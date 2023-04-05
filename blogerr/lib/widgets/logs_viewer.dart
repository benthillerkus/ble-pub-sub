import 'package:blogerr/logs.dart';
import 'package:blogerr/widgets/gap.dart';
import 'package:blogerr/widgets/phantom_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../definitions.dart';

class LogsViewer extends HookConsumerWidget {
  const LogsViewer({super.key});

  final hideIconBreakpoint = 800;
  final hideLabelBreakpoint = 600;
  final centerFiltersBreakpoint = 1100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = useState(const {Device.brain});
    final categories = useState(const <Category>{});
    final history = ref.watch(logProvider);
    final now = DateTime.now();

    final size = MediaQuery.of(context).size;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (size.width > centerFiltersBreakpoint) const PhantomIconButton(),
            Expanded(
              flex: size.width > centerFiltersBreakpoint ? 0 : 1,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: size.width > centerFiltersBreakpoint
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    SegmentedButton(
                        multiSelectionEnabled: true,
                        showSelectedIcon: false,
                        emptySelectionAllowed: true,
                        onSelectionChanged: (selection) =>
                            devices.value = selection,
                        segments: [
                          for (final device in Device.values)
                            ButtonSegment(
                                value: device,
                                icon: ((size.width < hideIconBreakpoint) &&
                                        size.width > hideLabelBreakpoint)
                                    ? null
                                    : Icon(
                                        device.icon,
                                        semanticLabel: device.label,
                                      ),
                                label: (size.width > hideLabelBreakpoint)
                                    ? Text(device.label)
                                    : null),
                        ],
                        selected: devices.value),
                    const Gap(16.0),
                    SegmentedButton(
                        multiSelectionEnabled: true,
                        showSelectedIcon: false,
                        emptySelectionAllowed: true,
                        onSelectionChanged: devices.value.isEmpty
                            ? (_) {}
                            : (Set<Category> selection) =>
                                categories.value = selection,
                        segments: [
                          for (final category in const {
                            Category.espNow,
                            Category.user,
                            Category.backend
                          })
                            ButtonSegment(
                              value: category,
                              icon: ((size.width < hideIconBreakpoint) &&
                                      size.width > hideLabelBreakpoint)
                                  ? null
                                  : Icon(
                                      category.icon,
                                      semanticLabel: category.label,
                                    ),
                              enabled: devices.value.isNotEmpty,
                              label: (size.width > hideLabelBreakpoint)
                                  ? Text(category.label)
                                  : null,
                            )
                        ],
                        selected: categories.value),
                  ],
                ),
              ),
            ),
            IconButton(
              onPressed: ref.read(logProvider).value?.clear,
              icon: const Icon(Icons.clear_all),
              tooltip: "Clear all logs",
            )
          ],
        ),
        const Gap(8.0),
        Builder(builder: (context) {
          return history.when(
            data: (data) {
              if (data.isEmpty) {
                return const Center(
                  child: Text("No logs yet"),
                );
              }
              return Expanded(
                child: ListView.builder(
                    itemBuilder: ((context, index) {
                      final log = data[data.length - 1 - index];

                      final isBrain = log.mac.toLowerCase() ==
                          Device.brain.label.toLowerCase();
                      final isBrainSelected =
                          devices.value.contains(Device.brain);
                      final isNodeSelected =
                          devices.value.contains(Device.node);

                      final childCategories = log.errors.entries
                          .where((element) =>
                              categories.value.isEmpty ||
                              categories.value.contains(element.key))
                          .toList();

                      if (childCategories.isEmpty ||
                          (devices.value.isNotEmpty &&
                              (isBrain && !isBrainSelected ||
                                  !isBrain && !isNodeSelected))) {
                        return const SizedBox.shrink();
                      }
                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        color: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: ListTile(
                            leading: Text(
                              "${now.difference(log.received).inSeconds}s\nago",
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            visualDensity: VisualDensity.comfortable,
                            isThreeLine: true,
                            title: Text(log.mac),
                            subtitle: Column(
                              children: [
                                for (final entry in childCategories)
                                  ListTile(
                                    dense: true,
                                    visualDensity: VisualDensity.compact,
                                    leading: Icon(entry.key.icon, size: 24),
                                    title: Text(entry.key.label),
                                    subtitle: Text(entry.value
                                        .map((e) => e.message)
                                        .join(", ")),
                                  ),
                                if (log.capErrors.isNotEmpty)
                                  const Placeholder()
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    itemCount: data.length),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stack) => Column(
              children: [Text(error.toString()), ErrorWidget(stack)],
            ),
          );
        }),
      ],
    );
  }
}
