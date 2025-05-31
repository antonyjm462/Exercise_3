import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ball Bucket Game',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
        textTheme: GoogleFonts.pressStart2pTextTheme(
          Theme.of(context).textTheme.apply(
            bodyColor: Colors.white,
            displayColor: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.yellow,
            foregroundColor: Colors.black,
            textStyle: GoogleFonts.pressStart2p(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.yellow,
            textStyle: GoogleFonts.pressStart2p(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.yellow,
            textStyle: GoogleFonts.pressStart2p(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      home: const BallBucketGame(),
    );
  }
}

class BallBucketGame extends StatefulWidget {
  const BallBucketGame({super.key});

  @override
  State<BallBucketGame> createState() => _BallBucketGameState();
}

class _BallBucketGameState extends State<BallBucketGame>
    with TickerProviderStateMixin {
  static const int totals = 8;
  static const int ballsPer = 10;
  static const double bucketYOffset = 10;
  static const double ballFallSpeed = 200;
  static const double spawnInterval = 1.0;

  int score = 0;
  int level = 1;
  int ballsCaught = 0;
  double bucketX = 0.0;
  double screenWidth = 0.0;
  double screenHeight = 0.0;
  double bucketWidth = 0.0;
  double bucketHeight = 0.0;
  double ballSize = 0.0;
  late Timer spawnTimer;
  late Ticker ticker;
  List<_Ball> balls = [];
  Random random = Random();
  bool gameStarted = false;
  bool gameOver = false;
  bool clearBallsNextTick = false;

  @override
  void initState() {
    super.initState();
    ticker = createTicker(_onTick);
  }

  void startGame() {
    setState(() {
      score = 0;
      level = 1;
      ballsCaught = 0;
      balls.clear();
      gameOver = false;
      gameStarted = true;
      bucketX = (screenWidth - bucketWidth) / 2;
    });
    ticker.start();
    spawnTimer = Timer.periodic(
      Duration(milliseconds: (spawnInterval * 1000).toInt()),
      (_) {
        _spawnBall();
      },
    );
  }

  void endGame() {
    setState(() {
      gameOver = true;
      gameStarted = false;
    });
    ticker.stop();
    spawnTimer.cancel();
  }

  void pauseGame() {
    if (gameStarted) {
      ticker.stop();
      setState(() {
        gameStarted = false;
      });
    }
  }

  void resumeGame() {
    if (!gameStarted && !gameOver) {
      ticker.start();
      setState(() {
        gameStarted = true;
      });
    }
  }

  void quitGame() {
    endGame();
  }

  void restartGame() {
    startGame();
  }

  void next() {
    setState(() {
      level++;
      ballsCaught = 0;
      clearBallsNextTick = true;
    });
  }

  void _onTick(Duration elapsed) {
    if (!gameStarted) return;
    double delta = 1 / 60.0;
    setState(() {
      for (final ball in balls) {
        ball.y += ballFallSpeed * delta;
      }
      balls.removeWhere((ball) {
        if (_isCaught(ball)) {
          score++;
          ballsCaught++;
          if (ballsCaught >= ballsPer) {
            if (level < totals) {
              next();
            } else {
              endGame();
            }
          }
          return true;
        }
        return ball.y > screenHeight;
      });
      if (clearBallsNextTick) {
        balls.clear();
        clearBallsNextTick = false;
      }
    });
  }

  bool _isCaught(_Ball ball) {
    double bucketTop = screenHeight - bucketHeight - bucketYOffset;
    double bucketLeft = bucketX;
    double bucketRight = bucketX + bucketWidth;
    double ballBottom = ball.y + ballSize;
    double ballCenterX = ball.x + ballSize / 2;
    double bucketBottom = bucketTop + bucketHeight;
    return ballBottom >= bucketTop &&
        ball.y <= bucketBottom &&
        ballCenterX >= bucketLeft &&
        ballCenterX <= bucketRight;
  }

  void _spawnBall() {
    if (!gameStarted) return;
    double x = random.nextDouble() * (screenWidth - ballSize);
    int ballImage = random.nextInt(9) + 1;
    balls.add(
      _Ball(x: x, y: -ballSize, image: 'lib/assets/balls/$ballImage.png'),
    );
  }

  @override
  void dispose() {
    ticker.dispose();
    if (gameStarted) spawnTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        screenWidth = constraints.maxWidth;
        screenHeight = constraints.maxHeight;
        bucketWidth = screenWidth * 0.30;
        bucketHeight = screenHeight * 0.20;
        ballSize = screenWidth * 0.15;
        if (!gameStarted) {
          bucketX = (screenWidth - bucketWidth) / 2;
        }
        return Scaffold(
          backgroundColor: const Color(0xFF6EC6F0),
          body: SafeArea(
            child: Stack(
              children: [
                Positioned.fill(
                  key: ValueKey<int>(level),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const double svgAspectRatio = 4.6;
                      final double bgWidth =
                          constraints.maxHeight * svgAspectRatio;
                      final double maxScroll = bgWidth - constraints.maxWidth;
                      final double scrollPosition =
                          maxScroll * ((level - 1) / (totals - 1));

                      return ClipRect(
                        child: OverflowBox(
                          maxWidth: bgWidth,
                          alignment: Alignment.topLeft,
                          child: Transform.translate(
                            offset: Offset(-scrollPosition, 0),
                            child: SizedBox(
                              width: bgWidth,
                              height: constraints.maxHeight,
                              child: SvgPicture.asset(
                                'lib/assets/background.svg',
                                fit: BoxFit.fitHeight,
                                alignment: Alignment.topLeft,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                ...balls.map(
                  (ball) => Positioned(
                    left: ball.x,
                    top: ball.y,
                    child: Image.asset(
                      ball.image,
                      width: ballSize,
                      height: ballSize,
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 50),
                  curve: Curves.linear,
                  left: bucketX,
                  top: screenHeight - bucketHeight - bucketYOffset,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      setState(() {
                        bucketX += details.delta.dx;
                        bucketX = bucketX.clamp(0.0, screenWidth - bucketWidth);
                      });
                    },
                    child: Image.asset(
                      'lib/assets/buckets/${level.clamp(1, totals)}.png',
                      width: bucketWidth,
                      height: bucketHeight,
                    ),
                  ),
                ),

                Positioned(
                  left: 16,
                  top: 16,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.yellow[700],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.sports_baseball,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 6),
                            Text('$score', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue[800],
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'LEVEL $level',
                          style: TextStyle(fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                ),

                Positioned(
                  right: 16,
                  top: 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.settings,
                      color: Colors.white,
                      size: 28,
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        barrierDismissible: true,
                        builder: (context) {
                          return AlertDialog(
                            backgroundColor: Colors.blue[800],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            title: Text(
                              'Settings',
                              textAlign: TextAlign.center,
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    pauseGame();
                                  },
                                  child: const Text('Pause'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    resumeGame();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Resume'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    quitGame();
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Quit'),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                if (!gameStarted || gameOver)
                  Positioned.fill(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (gameOver)
                            Text(
                              'Game Over!\nScore: $score',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 32),
                            ),
                          if (!gameOver)
                            Center(
                              child: Text(
                                'Ball Bucket Game',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 32),
                              ),
                            ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () {
                              startGame();
                            },
                            child: Text(gameOver ? 'Restart' : 'Start'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Ball {
  double x;
  double y;
  final String image;
  _Ball({required this.x, required this.y, required this.image});
}
