import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  late Ticker _ticker;
  final Random _random = Random();

  // Game State
  bool _isPlaying = false;
  bool _isGameOver = false;
  int _score = 0;
  double _difficultyMultiplier = 1.0;

  // Player
  double _playerX = 0.0;
  double _playerY = 0.0;
  final double _playerSize = 50.0;
  final double _playerSpeed = 5.0; // For keyboard/smooth movement if needed

  // Game Objects
  List<Bullet> _bullets = [];
  List<Enemy> _enemies = [];
  List<Particle> _particles = [];
  List<Star> _stars = [];

  // Screen Dimensions
  double _screenWidth = 0.0;
  double _screenHeight = 0.0;

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_onTick);
    
    // Initialize stars for background
    for (int i = 0; i < 100; i++) {
      _stars.add(Star(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: _random.nextDouble() * 2 + 1,
        speed: _random.nextDouble() * 0.002 + 0.0005,
      ));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _screenWidth = MediaQuery.of(context).size.width;
    _screenHeight = MediaQuery.of(context).size.height;
    
    // Center player initially
    if (!_isPlaying && !_isGameOver) {
      _playerX = _screenWidth / 2 - _playerSize / 2;
      _playerY = _screenHeight - _playerSize - 50;
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      _isPlaying = true;
      _isGameOver = false;
      _score = 0;
      _difficultyMultiplier = 1.0;
      _bullets.clear();
      _enemies.clear();
      _particles.clear();
      _playerX = _screenWidth / 2 - _playerSize / 2;
      _playerY = _screenHeight - _playerSize - 50;
    });
    _ticker.start();
  }

  void _gameOver() {
    _ticker.stop();
    setState(() {
      _isPlaying = false;
      _isGameOver = true;
    });
  }

  void _onTick(Duration elapsed) {
    setState(() {
      _updateGameLogic();
    });
  }

  void _updateGameLogic() {
    // 1. Update Stars (Background)
    for (var star in _stars) {
      star.y += star.speed * (_isPlaying ? 5 : 1); // Move faster when playing
      if (star.y > 1.0) {
        star.y = 0.0;
        star.x = _random.nextDouble();
      }
    }

    if (!_isPlaying) return;

    // Increase difficulty
    _difficultyMultiplier += 0.0005;

    // 2. Spawn Enemies
    if (_random.nextDouble() < 0.02 * _difficultyMultiplier) {
      _enemies.add(Enemy(
        x: _random.nextDouble() * (_screenWidth - 40),
        y: -50,
        speed: (2.0 + _random.nextDouble() * 3.0) * (_difficultyMultiplier * 0.8),
        type: _random.nextInt(3), // 0: Basic, 1: Fast, 2: Tank
        hp: _random.nextInt(3) == 2 ? 3 : 1,
      ));
    }

    // 3. Move Bullets
    for (var bullet in _bullets) {
      bullet.y -= 10.0;
    }
    _bullets.removeWhere((bullet) => bullet.y < -20);

    // 4. Move Enemies
    for (var enemy in _enemies) {
      enemy.y += enemy.speed;
    }

    // 5. Collision Detection
    // Bullet vs Enemy
    List<Bullet> bulletsToRemove = [];
    List<Enemy> enemiesToRemove = [];

    for (var bullet in _bullets) {
      for (var enemy in _enemies) {
        if (!bulletsToRemove.contains(bullet) && !enemiesToRemove.contains(enemy)) {
          if (_checkCollision(
              bullet.x, bullet.y, 10, 20, enemy.x, enemy.y, 40, 40)) {
            
            bullet.active = false;
            bulletsToRemove.add(bullet);
            
            enemy.hp--;
            if (enemy.hp <= 0) {
              enemy.active = false;
              enemiesToRemove.add(enemy);
              _score += (10 * _difficultyMultiplier).toInt();
              _spawnExplosion(enemy.x + 20, enemy.y + 20, Colors.orange);
            } else {
              _spawnExplosion(enemy.x + 20, enemy.y + 20, Colors.white, count: 3);
            }
          }
        }
      }
    }

    // Player vs Enemy
    Rect playerRect = Rect.fromLTWH(_playerX + 10, _playerY + 10, _playerSize - 20, _playerSize - 20);
    for (var enemy in _enemies) {
      if (enemy.active) {
        Rect enemyRect = Rect.fromLTWH(enemy.x, enemy.y, 40, 40);
        if (playerRect.overlaps(enemyRect)) {
          _spawnExplosion(_playerX + _playerSize/2, _playerY + _playerSize/2, Colors.cyanAccent, count: 50);
          _gameOver();
        }
      }
    }

    // Cleanup
    _bullets.removeWhere((b) => !b.active);
    _enemies.removeWhere((e) => !e.active || e.y > _screenHeight);

    // 6. Update Particles
    for (var particle in _particles) {
      particle.x += particle.vx;
      particle.y += particle.vy;
      particle.life -= 0.05;
      particle.opacity = particle.life.clamp(0.0, 1.0);
    }
    _particles.removeWhere((p) => p.life <= 0);
  }

  bool _checkCollision(double x1, double y1, double w1, double h1, double x2, double y2, double w2, double h2) {
    return x1 < x2 + w2 && x1 + w1 > x2 && y1 < y2 + h2 && y1 + h1 > y2;
  }

  void _spawnExplosion(double x, double y, Color color, {int count = 10}) {
    for (int i = 0; i < count; i++) {
      double angle = _random.nextDouble() * 2 * pi;
      double speed = _random.nextDouble() * 5 + 2;
      _particles.add(Particle(
        x: x,
        y: y,
        vx: cos(angle) * speed,
        vy: sin(angle) * speed,
        color: color,
        life: 1.0,
      ));
    }
  }

  void _fireBullet() {
    if (!_isPlaying) return;
    setState(() {
      _bullets.add(Bullet(
        x: _playerX + _playerSize / 2 - 5,
        y: _playerY,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (details) {
          if (_isPlaying) {
            setState(() {
              _playerX += details.delta.dx;
              _playerY += details.delta.dy;
              
              // Clamp to screen
              _playerX = _playerX.clamp(0.0, _screenWidth - _playerSize);
              _playerY = _playerY.clamp(0.0, _screenHeight - _playerSize);
            });
          }
        },
        onTapDown: (_) => _fireBullet(), // Tap to shoot
        child: Stack(
          children: [
            // Background
            CustomPaint(
              painter: StarFieldPainter(_stars),
              size: Size(_screenWidth, _screenHeight),
            ),

            // Game Layer
            if (_isPlaying || _isGameOver) ...[
              // Bullets
              ..._bullets.map((b) => Positioned(
                left: b.x,
                top: b.y,
                child: Container(
                  width: 10,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.yellowAccent,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(color: Colors.yellow.withOpacity(0.5), blurRadius: 5, spreadRadius: 2)
                    ]
                  ),
                ),
              )),

              // Enemies
              ..._enemies.map((e) => Positioned(
                left: e.x,
                top: e.y,
                child: _buildEnemyWidget(e),
              )),

              // Particles
              ..._particles.map((p) => Positioned(
                left: p.x,
                top: p.y,
                child: Opacity(
                  opacity: p.opacity,
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: p.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              )),

              // Player
              Positioned(
                left: _playerX,
                top: _playerY,
                child: _buildPlayerWidget(),
              ),
              
              // Auto-fire hint (invisible touch area for rapid fire if user prefers tapping)
            ],

            // HUD
            Positioned(
              top: 40,
              left: 20,
              child: Text(
                'SCORE: $_score',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(color: Colors.blue, blurRadius: 10)],
                ),
              ),
            ),

            // Start / Game Over Screen
            if (!_isPlaying)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.cyanAccent, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.cyanAccent.withOpacity(0.3), blurRadius: 20, spreadRadius: 5)
                    ]
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _isGameOver ? 'GAME OVER' : 'EPIC SPACE\nDEFENDER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _isGameOver ? Colors.redAccent : Colors.cyanAccent,
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (_isGameOver)
                        Text(
                          'Final Score: $_score',
                          style: const TextStyle(color: Colors.white, fontSize: 24),
                        ),
                      const SizedBox(height: 40),
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purpleAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          textStyle: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        child: Text(_isGameOver ? 'RETRY' : 'START MISSION'),
                      ),
                    ],
                  ),
                ),
              ),
              
            // Fire Button (Bottom Right)
            if (_isPlaying)
              Positioned(
                bottom: 40,
                right: 40,
                child: GestureDetector(
                  onTap: _fireBullet, // Rapid tap
                  onLongPress: () {
                    // Could implement auto-fire here
                  }, 
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.redAccent, width: 2),
                    ),
                    child: const Icon(Icons.my_location, color: Colors.white, size: 40),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerWidget() {
    return Container(
      width: _playerSize,
      height: _playerSize,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.cyanAccent, blurRadius: 15, spreadRadius: 2)
        ]
      ),
      child: const Icon(Icons.rocket_launch, color: Colors.white, size: 40),
    );
  }

  Widget _buildEnemyWidget(Enemy enemy) {
    Color color;
    IconData icon;
    
    switch (enemy.type) {
      case 1: // Fast
        color = Colors.yellowAccent;
        icon = Icons.bolt;
        break;
      case 2: // Tank
        color = Colors.redAccent;
        icon = Icons.android;
        break;
      default: // Basic
        color = Colors.greenAccent;
        icon = Icons.bug_report;
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.6), blurRadius: 10, spreadRadius: 1)
        ]
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

// --- Data Models & Painters ---

class Bullet {
  double x;
  double y;
  bool active = true;
  Bullet({required this.x, required this.y});
}

class Enemy {
  double x;
  double y;
  double speed;
  int type;
  int hp;
  bool active = true;
  Enemy({required this.x, required this.y, required this.speed, required this.type, required this.hp});
}

class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double life;
  Color color;
  double opacity = 1.0;
  Particle({required this.x, required this.y, required this.vx, required this.vy, required this.color, required this.life});
}

class Star {
  double x; // 0.0 to 1.0
  double y; // 0.0 to 1.0
  double size;
  double speed;
  Star({required this.x, required this.y, required this.size, required this.speed});
}

class StarFieldPainter extends CustomPainter {
  final List<Star> stars;
  StarFieldPainter(this.stars);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white;
    for (var star in stars) {
      paint.strokeWidth = star.size;
      paint.color = Colors.white.withOpacity(0.5 + (star.speed * 100).clamp(0.0, 0.5));
      canvas.drawPoints(PointMode.points, [Offset(star.x * size.width, star.y * size.height)], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
