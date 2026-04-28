enum PlatformType {
  bilibili('bilibili', 'B站'),
  douyu('douyu', '斗鱼'),
  huya('huya', '虎牙'),
  douyin('douyin', '抖音');

  final String id;
  final String displayName;

  const PlatformType(this.id, this.displayName);
}
