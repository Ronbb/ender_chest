import 'dart:async';
import 'dart:developer';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:super_clipboard/super_clipboard.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'model.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Content(),
    );
  }
}

class Content extends StatefulWidget {
  const Content({super.key});

  @override
  State<Content> createState() => _ContentState();
}

class _ContentState extends State<Content>
    with ClipboardListener, TrayListener {
  bool _reading = false;
  StreamSubscription<DateTime>? _subscription;
  final _data = <ClipboardDataBase>[];
  final _events = StreamController<DateTime>();

  @override
  void initState() {
    trayManager.addListener(this);
    clipboardWatcher.addListener(this);
    clipboardWatcher.start();
    _subscription = _events.stream.listen((event) {
      _safelyRead();
    });
    super.initState();
  }

  @override
  void dispose() {
    clipboardWatcher.stop();
    clipboardWatcher.removeListener(this);
    trayManager.removeListener(this);
    _events.close();
    _subscription?.cancel();
    super.dispose();
  }

  @override
  void onTrayIconMouseDown() async {
    await windowManager.restore();
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  void onClipboardChanged() async {
    _events.add(DateTime.now());
  }

  void _safelyRead() async {
    if (_reading) {
      return;
    }

    _reading = true;

    await Future.delayed(const Duration(milliseconds: 10));

    try {
      final reader = await ClipboardReader.readClipboard();

      if (reader.canProvide(Formats.plainText)) {
        _safelyAdd(TextData(
          (await reader.readValue(Formats.plainText))!,
        ));
        return;
      }

      if (reader.canProvide(Formats.fileUri)) {
        _safelyAdd(
          FileData(
            (await reader.readValue(Formats.fileUri))!,
          ),
        );
        return;
      }
      log('unknown format: ${reader.platformFormats}');
    } catch (e) {
      log('error reader: $e');
    }

    _reading = false;
  }

  void _safelyAdd(ClipboardDataBase data) {
    _data.add(data);
    _reading = false;

    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scrollbar(
      child: CustomScrollView(
        primary: true,
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 112.0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Ender Chest',
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      style: theme.textTheme.headlineLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        if (kDebugMode) {
                          return;
                        }
                        windowManager.close();
                      },
                      icon: Icon(
                        Icons.close_outlined,
                        color: theme.colorScheme.primary,
                      ),
                    )
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList.separated(
              itemCount: _data.length,
              separatorBuilder: (context, index) {
                return const Divider();
              },
              itemBuilder: (context, index) {
                final reversedIndex = _data.length - index - 1;
                final data = _data[reversedIndex];
                final message = data
                    .buildMessage(context)
                    .trim()
                    .replaceAll(RegExp(r'\s+'), '')
                    .replaceAllMapped(
                      RegExp(r'\S'),
                      (match) => '\u200B${match[0]}',
                    );
                return ListTile(
                  key: ObjectKey(data),
                  onTap: () async {
                    try {
                      await clipboardWatcher.stop();

                      final item = DataWriterItem();
                      if (data is TextData) {
                        item.add(Formats.plainText(data.text));
                      } else if (data is FileData) {
                        item.add(Formats.fileUri(data.uri));
                      }

                      if (item.data.isNotEmpty) {
                        await ClipboardWriter.instance.write([item]);
                      }

                      if (mounted) {
                        ScaffoldMessenger.of(context)
                          ..hideCurrentSnackBar()
                          ..showSnackBar(
                            SnackBar(
                              content: Text(
                                'copied: $message',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            ),
                          );
                      }
                    } catch (e) {
                      log('error copy: $e');
                    } finally {
                      await clipboardWatcher.start();
                    }
                  },
                  leading: Text('${reversedIndex + 1}'),
                  trailing: IconButton(
                    onPressed: () {
                      setState(() {
                        _data.removeAt(reversedIndex);
                      });
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text(
                              'deleted: $message',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                          ),
                        );
                    },
                    icon: Icon(
                      Icons.delete_outlined,
                      color: theme.colorScheme.secondary.withOpacity(0.38),
                    ),
                  ),
                  title: Text(
                    message,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
