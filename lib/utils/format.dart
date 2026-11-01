String formatDuration(Duration d) {
  final hours = d.inHours;
  final minutes = (d.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
