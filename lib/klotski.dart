import 'package:flutter/material.dart';
import 'package:awesome_dialog/awesome_dialog.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:dio/dio.dart';

class Klotski extends StatefulWidget {
  const Klotski({super.key});

  @override
  State<Klotski> createState() => _KlotskiState();
}

class _KlotskiState extends State<Klotski> {
  double phoneWidth = 0.0;
  double phoneHeight = 0.0;
  int steps = 0;
  bool isGameStarted = false;
  bool isWon = false;
  bool isGraph = true;
  bool isLoading = false;

  DateTime startTime = DateTime.now();

  final Dio dio = Dio();
  final stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countUp);

  // 游戏状态
  List<List<int>> state = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 0]
  ];

  // 胜利状态
  List<List<int>> winState = [
    [1, 2, 3],
    [4, 5, 6],
    [7, 8, 0]
  ];

  // 块的颜色
  List<Color> blockColors = const [
    Color.fromARGB(255, 255, 255, 255),
    Color.fromARGB(255, 255, 239, 151),
    Color.fromARGB(255, 253, 184, 250),
    Color.fromARGB(255, 255, 183, 183),
    Color.fromARGB(255, 255, 230, 183),
    Color.fromARGB(255, 183, 255, 221),
    Color.fromARGB(255, 151, 239, 255),
    Color.fromARGB(255, 221, 183, 255),
    Color.fromARGB(255, 255, 195, 227),
  ];

  @override
  void initState() {
    super.initState();
    stopWatchTimer.setPresetTime(mSec: 0);
    randomizeState();
    // state = winState;
  }

  @override
  void dispose() async {
    super.dispose();
    await stopWatchTimer.dispose();
  }

  // 随机打乱华容道
  void randomizeState() {
    final List<int> numbers = List.generate(9, (i) => i);
    for (int i = 0; i < 100; i++) {
      final int index = numbers.indexOf(0);
      final List<int> possibleMoves = [];
      if (index % 3 > 0) {
        possibleMoves.add(index - 1);
      }
      if (index % 3 < 2) {
        possibleMoves.add(index + 1);
      }
      if (index ~/ 3 > 0) {
        possibleMoves.add(index - 3);
      }
      if (index ~/ 3 < 2) {
        possibleMoves.add(index + 3);
      }
      final int move = possibleMoves[
          (DateTime.now().microsecondsSinceEpoch % possibleMoves.length)];
      numbers[index] = numbers[move];
      numbers[move] = 0;
    }
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        state[i][j] = numbers[i * 3 + j];
      }
    }
  }

  void randomizeState2() {
    state = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 0, 8]
    ];
  }

  // 判断游戏是否结束
  bool isGameFinised() {
    // 最后一个格子不是空格，肯定没结束
    if (state[2][2] != 0) {
      return false;
    }

    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (state[i][j] != winState[i][j]) {
          return false;
        }
      }
    }
    return true;
  }

  // 游戏棋盘
  Widget getGameBoard() {
    return Container(
      width: phoneWidth * 0.8,
      height: phoneWidth * 0.8,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 1),
      ),
      child: Column(
        children: List.generate(3, (i) {
          return Row(
            children: List.generate(3, (j) {
              return GestureDetector(
                // 滑动
                onPanUpdate: (details) {
                  // 游戏未开始不能操作
                  if (!isGameStarted) {
                    return;
                  }
                  if (state[i][j] == 0) {
                    return;
                  }
                  if (details.delta.dx.abs() > details.delta.dy.abs()) {
                    if (details.delta.dx > 0) {
                      if (j < 2 && state[i][j + 1] == 0) {
                        state[i][j + 1] = state[i][j];
                        state[i][j] = 0;
                        steps++;
                      }
                    } else {
                      if (j > 0 && state[i][j - 1] == 0) {
                        state[i][j - 1] = state[i][j];
                        state[i][j] = 0;
                        steps++;
                      }
                    }
                  } else {
                    if (details.delta.dy > 0) {
                      if (i < 2 && state[i + 1][j] == 0) {
                        state[i + 1][j] = state[i][j];
                        state[i][j] = 0;
                        steps++;
                      }
                    } else {
                      if (i > 0 && state[i - 1][j] == 0) {
                        state[i - 1][j] = state[i][j];
                        state[i][j] = 0;
                        steps++;
                      }
                    }
                  }
                  // 判断游戏是否结束
                  if (isGameFinised()) {
                    stopWatchTimer.onStopTimer();
                    isGameStarted = false;
                    isWon = true;
                    debugPrint(
                        'You win! Time: ${stopWatchTimer.rawTime.value}');
                    AwesomeDialog(
                      context: context,
                      dialogType: DialogType.success,
                      animType: AnimType.topSlide,
                      btnOkText: '再来一局',
                      title: '恭喜你！你胜利了！',
                      desc:
                          '用时: ${StopWatchTimer.getDisplayTime(stopWatchTimer.rawTime.value, hours: false)}\n步数: $steps',
                      descTextStyle: const TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontFamily: 'BalooBhai',
                      ),
                      btnOkOnPress: () {
                        // 重置计时
                        stopWatchTimer.onResetTimer();
                        // 重置游戏
                        isGameStarted = false;
                        // 重置步数
                        steps = 0;
                        // 重置游戏状态
                        randomizeState();
                        setState(() {});
                      },
                    ).show();
                  }
                  setState(() {});
                },
                child: Container(
                  width: (phoneWidth * 0.8 / 3) - 1,
                  height: (phoneWidth * 0.8 / 3) - 1,
                  decoration: BoxDecoration(
                    color: isGraph
                        ? Colors.white
                        : blockColors[(state[i][j]) % blockColors.length],
                    // 数字时黑色，图片时白色
                    border: Border.all(
                        color: isGraph ? Colors.white : Colors.black, width: 1),
                  ),
                  child: Center(
                    child: isGraph
                        // 图片
                        ? state[i][j] == 0
                            ? const SizedBox()
                            : Image.asset(
                                'assets/images/gate${state[i][j]}.jpeg',
                              )
                        // 数字
                        : Text(
                            state[i][j] == 0 ? '' : state[i][j].toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 40,
                              fontFamily: 'BalooBhai',
                            ),
                          ),
                  ),
                ),
              );
            }),
          );
        }),
      ),
    );
  }

  // 统计游戏时长与步数
  Widget getGameInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
      child: SizedBox(
        width: phoneWidth * 0.8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            StreamBuilder(
                stream: stopWatchTimer.rawTime,
                builder: (context, snap) {
                  final int? value = snap.data;
                  String displayTime = '00:00.00';
                  if (value != null) {
                    displayTime =
                        StopWatchTimer.getDisplayTime(value, hours: false);
                  }
                  return Text(
                    '时间: $displayTime',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 23,
                      fontFamily: 'rifu',
                    ),
                  );
                }),
            Text(
              '步数: ${steps.toString()}',
              style: const TextStyle(
                color: Colors.black,
                fontSize: 23,
                fontFamily: 'rifu',
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 游戏说明
  Widget getInfo(String content, [bool textAlign = false]) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 5),
      child: Text(
        content,
        style: const TextStyle(
          color: Colors.black,
          fontSize: 20,
          fontFamily: 'BalooBhai',
        ),
        textAlign: textAlign ? TextAlign.center : TextAlign.start,
      ),
    );
  }

  // 游戏模式
  Widget getGameMode() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      child: SizedBox(
        width: phoneWidth * 0.8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // 刷新棋盘按钮
            GestureDetector(
              onTap: () {
                isGraph = !isGraph;
                setState(() {});
              },
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.black),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(5),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/icons/${isGraph ? 'picture' : 'number'}.png',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isGraph ? '图片模式' : '数字模式',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontFamily: 'rifu',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(width: 20),
            // 提示 i按钮
            GestureDetector(
              onTap: () {
                // 显示图片
                AwesomeDialog(
                  context: context,
                  dialogType: DialogType.info,
                  animType: AnimType.bottomSlide,
                  btnOkText: '确定',
                  buttonsTextStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'rifu',
                  ),
                  body: Container(
                    color: Colors.white,
                    child: Column(children: [
                      const Text(
                        '华容道',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 25,
                          fontFamily: 'rifu',
                        ),
                      ),
                      const SizedBox(height: 10),
                      isGraph
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
                              child: Image.asset(
                                'assets/images/gate.jpg',
                              ),
                            )
                          : Image.asset(
                              'assets/images/number.png',
                            ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            getInfo(
                                '华容道是一款益智游戏，游戏目标是将编号为1-8或图片的方块移动到正确的位置，最终将编号为0的方块移动到最下方的中间位置。'),
                            const SizedBox(height: 10),
                            getInfo('游戏规则：', true),
                            getInfo('1. 点击开始游戏按钮开始游戏，点击结束游戏按钮结束游戏。'),
                            getInfo('2. 点击刷新棋盘按钮可以重新开始游戏。'),
                            getInfo(
                                '3. 点击AI游玩按钮可以开启AI自动游玩，点击AI游玩按钮可以关闭AI自动游玩。'),
                            getInfo('4. 点击棋盘上的方块可以移动方块，将方块移动到正确的位置。'),
                            getInfo('5. 游戏结束后会弹出胜利提示框，点击确定按钮可以重新开始游戏。'),
                            getInfo('6. 点击图片模式按钮可以切换图片模式和数字模式。'),
                            getInfo('7. 当所有方块移动到正确的位置时，游戏胜利。可以参考上面的示例图'),
                            getInfo('祝你游戏愉快！', true)
                          ],
                        ),
                      ),
                    ]),
                  ),
                  btnOkOnPress: () {},
                ).show();
              },
              child: const Icon(
                Icons.info,
                color: Colors.black,
                size: 30,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 游戏按钮
  Widget getGameButtons() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 10),
          child: SizedBox(
            width: phoneWidth * 0.8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // 刷新棋盘按钮
                GestureDetector(
                  onTap: () {
                    // 游戏开始后不允许刷新棋盘
                    if (isGameStarted) {
                      return;
                    }
                    // 重置棋盘
                    randomizeState();
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          Image.asset(
                            'assets/icons/refresh.png',
                            width: 20,
                            height: 20,
                          ),
                          const SizedBox(width: 5),
                          const Text(
                            '刷新棋盘',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: 'rifu',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // 开始/结束游戏按钮
                GestureDetector(
                  onTap: () {
                    // 开始游戏
                    if (!isGameStarted) {
                      stopWatchTimer.onStartTimer();
                      isGameStarted = true;
                      // randomizeState();
                    }
                    // 结束游戏
                    else {
                      // 暂停计时
                      stopWatchTimer.onStopTimer();

                      // 出现提示框:确认退出游戏
                      AwesomeDialog(
                        context: context,
                        dialogType: DialogType.warning,
                        animType: AnimType.rightSlide,
                        title: '退出游戏',
                        desc: '确定要退出游戏吗？',
                        btnCancelOnPress: () {
                          // 继续计时
                          stopWatchTimer.onStartTimer();
                        },
                        btnOkOnPress: () {
                          // 重置计时
                          stopWatchTimer.onResetTimer();
                          // 重置游戏
                          isGameStarted = false;
                          // 重置步数
                          steps = 0;
                          // 重置游戏状态
                          randomizeState();
                          setState(() {});
                        },
                      ).show();
                    }
                    setState(() {});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.black),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Row(
                        children: [
                          // 图片icon
                          Image.asset(
                            isGameStarted
                                ? 'assets/icons/stop.png'
                                : 'assets/icons/start.png',
                            width: 20,
                            height: 20,
                          ),

                          const SizedBox(width: 5),

                          Text(
                            isGameStarted ? '结束游戏' : '开始游戏',
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 20,
                              fontFamily: 'rifu',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    phoneWidth = MediaQuery.of(context).size.width;
    phoneHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '华容道',
          style: TextStyle(fontFamily: 'rifu', fontSize: 28),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color.fromARGB(255, 99, 166, 243),
                Color.fromARGB(255, 179, 248, 253),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        constraints: const BoxConstraints.expand(),
        // 游戏主体
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            getGameMode(),
            getGameInfo(),
            getGameBoard(),
            getGameButtons(),
          ],
        ),
      ),
    );
  }
}
