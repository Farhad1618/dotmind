enum Look {
  classic,
  icons,
  pixel;

  static Look named(String? name) {
    for (final look in values) {
      if (look.name == name) return look;
    }
    return classic;
  }
}
