import 'package:flame/components.dart';
import 'dart:math'; 
import '../../common/protocol.dart';

class ExplosionVisual extends Component { 
  final ExplosionModel model;
  double _lifeTime = 0.0;

  ExplosionVisual(this.model);

  @override
  Future<void> onLoad() async {
    // We use findGame to get the image reference
    final image = await findGame()!.images.load('tileSet-2.png');
    
    SpriteAnimation createAnim(double xStart, double yStart, int count) {
      final sprites = <Sprite>[];
      for (int i = 0; i < count; i++) {
        sprites.add(Sprite(image, srcPosition: Vector2(xStart + (i * 16), yStart), srcSize: Vector2(16, 16)));
      }
      return SpriteAnimation.spriteList(sprites, stepTime: 0.1, loop: true); 
    }

    final centerAnim = createAnim(48, 816, 5);
    final northAnim  = createAnim(0, 832, 4);
    final southAnim  = createAnim(0, 864, 4);
    final westAnim   = createAnim(64, 832, 4); 
    final eastAnim   = createAnim(64, 864, 4); 
    final vertAnim   = createAnim(0, 848, 4);  
    final horzAnim   = createAnim(64, 848, 4); 

    int minX = 999, maxX = -999, minY = 999, maxY = -999;
    for (var tile in model.affectedTiles) {
      minX = min(minX, tile[0]);
      maxX = max(maxX, tile[0]);
      minY = min(minY, tile[1]);
      maxY = max(maxY, tile[1]);
    }

    for (int i = 0; i < model.affectedTiles.length; i++) {
      final tile = model.affectedTiles[i]; 
      final Vector2 pos = Vector2(tile[0] * 32.0, tile[1] * 32.0);
      
      SpriteAnimationComponent animComp;
      
      if (i == 0) {
        animComp = SpriteAnimationComponent(animation: centerAnim, position: pos, size: Vector2(32,32), priority: 9);
      } else {
        int cx = model.affectedTiles[0][0];
        int tx = tile[0];
        int ty = tile[1];

        if (tx == cx) {
           if (ty == minY) animComp = SpriteAnimationComponent(animation: northAnim, position: pos, size: Vector2(32,32), priority: 7);
           else if (ty == maxY) animComp = SpriteAnimationComponent(animation: southAnim, position: pos, size: Vector2(32,32), priority: 7);
           else animComp = SpriteAnimationComponent(animation: vertAnim, position: pos, size: Vector2(32,32), priority: 8);
        } else {
           if (tx == minX) animComp = SpriteAnimationComponent(animation: westAnim, position: pos, size: Vector2(32,32), priority: 7);
           else if (tx == maxX) animComp = SpriteAnimationComponent(animation: eastAnim, position: pos, size: Vector2(32,32), priority: 7);
           else animComp = SpriteAnimationComponent(animation: horzAnim, position: pos, size: Vector2(32,32), priority: 8);
        }
      }
      
      // Add child to THIS component so they are removed together
      add(animComp);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _lifeTime += dt;
    // Remove after 1 second (Server Hitbox Duration)
    if (_lifeTime >= 1.0) {
      removeFromParent();
    }
  }
}