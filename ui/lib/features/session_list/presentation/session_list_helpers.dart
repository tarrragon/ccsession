/// 需求：從 projectPath 提取專案名稱（最後一段路徑）
/// 範例：'/Users/foo/Projects/myapp' -> 'myapp'
/// 邊界：空字串 -> ''；'/' -> ''；無斜線 -> 原字串
String extractProjectName(String projectPath) {
  if (projectPath.isEmpty) {
    return '';
  }

  var path = projectPath;

  // 移除尾部斜線
  while (path.length > 1 && path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }

  if (path == '/') {
    return '';
  }

  final lastSlashIndex = path.lastIndexOf('/');
  if (lastSlashIndex < 0) {
    return path;
  }

  return path.substring(lastSlashIndex + 1);
}
