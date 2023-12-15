import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  List<List<int>> piskvorky = List.generate(
      3, (_) => List.filled(3, 0, growable: false),
      growable: false);

  void clicked(int index) {
    if (me == null || gameId == null) {
      showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Choose game mode'),
            content: const Text('Start a new game or connect to one.'),
            actions: [
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return;
    }
    if (me == lastMove && tah != 0) {
      return;
    }
    lastMove = me;
    FirebaseFirestore.instance
        .collection('games')
        .doc(gameId)
        .collection('moves')
        .add({
      'date': FieldValue.serverTimestamp(),
      'move': {'y': index ~/ 3, 'x': index % 3},
      'player': me,
    });
  }

  int? me;
  int? lastMove;
  String? gameId;

  var score = [0, 0];

  void init() {
    piskvorky = List.generate(3, (_) => List.filled(3, 0, growable: false),
        growable: false);
    lastMove = 0;
    lastMoveMap = null;
    vyhralHrac = 0;
    tah = 0;
  }

  void clearScore() {
    score = [0, 0];
  }

  Future<String?> createGame() async {
    final result = await FirebaseFirestore.instance
        .collection('games')
        .add({'created': FieldValue.serverTimestamp()});
    setState(() {
      // gameId = 'vilskgEXGxngdTejGvTQ';
      gameId = result.id;
      initIsExecuting = true;
      init();
      clearScore();
    });
    me = 1;
    return gameId;
  }

  var initIsExecuting = false;

  Future<bool> gameExist(String? gameId) async {
    if (gameId == null) {
      return false;
    }
    final result =
        await FirebaseFirestore.instance.collection('games').doc(gameId).get();
    if (result.exists) {
      me = 2;
      setState(() {
        this.gameId = gameId;
      });
      return true;
    }
    return false;
  }

  int vyhralHrac = 0;
  bool koniecHry = false;
  int tah = 0;

  void checkIfEndGame() {
    if (vyhralHrac > 0) {
      score[vyhralHrac - 1]++;
      koniecHry = true;
    } else if (tah == 9) {
      score[0]++;
      score[1]++;
      koniecHry = true;
    }
    if (koniecHry) {
      init();
      koniecHry = false;
    }
  }

  void check() {
    // kontrola riadkov, stlpcov a diagonal
    for (int riadokStlpecDiagonala = 0;
        riadokStlpecDiagonala < 4;
        riadokStlpecDiagonala++) {
      for (int y = 0; y < 3; y++) {
        for (int hrac = 0; hrac < 2; hrac++) {
          if (vyhralHrac == 0) {
            for (int x = 0; x < 3; x++) {
              int pomX = x;
              int pomY = y;
              if (riadokStlpecDiagonala == 1) {
                pomY = x;
                pomX = y;
              } else if (riadokStlpecDiagonala == 2) {
                pomY = x;
              } else if (riadokStlpecDiagonala == 3) {
                pomY = x;
                pomX = 3 - 1 - x;
              }
              if (piskvorky[pomY][pomX] != hrac + 1) {
                vyhralHrac = 0;
                break;
              }
              vyhralHrac = hrac + 1;
            }
          }
        }
        if (riadokStlpecDiagonala > 1) {
          break;
        }
      }
    }
    checkIfEndGame();
  }

  Map<String, dynamic>? lastMoveMap;

  void printToSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void tryToConnect(String? gameId) async {
    final exists = await gameExist(gameId);
    if (exists) {
      printToSnackBar('Game started');
      setState(() {
        init();
        clearScore();
      });
    } else {
      printToSnackBar('Game does not exists');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tic tac toe'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            tooltip: 'New game',
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: const Text('New game'),
                    content: const Text('Start a new game?'),
                    actions: [
                      TextButton(
                        child: const Text('Cancel'),
                        onPressed: () {
                          Navigator.of(context).pop(false);
                        },
                      ),
                      TextButton(
                        child: const Text('Start'),
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                      ),
                    ],
                  );
                },
              );
              if (result == true) {
                createGame();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_add),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            tooltip: 'Connect',
            onPressed: () async {
              String gameId = '';
              await showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Enter game ID'),
                    content: TextField(
                      decoration: const InputDecoration(hintText: 'Game ID'),
                      onChanged: (value) {
                        gameId = value;
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          tryToConnect(gameId);
                          Navigator.of(context).pop();
                        },
                        child: const Text('Save'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<Object>(
          stream: FirebaseFirestore.instance
              .collection('games')
              .doc(gameId)
              .collection('moves')
              .orderBy('date', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.data != null) {
              final data = snapshot.data as QuerySnapshot<Map<String, dynamic>>;
              final docs = data.docs;
              if (docs.isNotEmpty) {
                final docData = docs[0].data();
                final player = docData['player'];
                final move = docData['move'] as Map<String, dynamic>;
                lastMove = player;
                if (!initIsExecuting &&
                    (lastMoveMap == null ||
                        lastMoveMap!['x'] != move['x'] ||
                        lastMoveMap!['y'] != move['y'])) {
                  piskvorky[move['y']][move['x']] = player;
                  tah++;
                  check();
                }
                initIsExecuting = false;
                lastMoveMap = move;
              }
            }
            return SingleChildScrollView(
              child: Column(
                children: [
                  GridView.builder(
                      itemCount: 9,
                      shrinkWrap: true,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3),
                      itemBuilder: (BuildContext context, int index) {
                        final data = piskvorky[index ~/ 3][index % 3];
                        return GestureDetector(
                          onTap: () {
                            clicked(index);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                border: Border.all(color: Colors.black)),
                            child: Center(
                              child: Text(
                                data == 0
                                    ? ''
                                    : data == 1
                                        ? 'X'
                                        : 'O',
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 50),
                              ),
                            ),
                          ),
                        );
                      }),
                  const SizedBox(height: 24),
                  if (gameId != null)
                    GestureDetector(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(gameId ?? ''),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.copy,
                            size: 14,
                          ),
                        ],
                      ),
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: gameId));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Copied'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    )
                  else
                    const SizedBox(height: 16),
                  const SizedBox(height: 24),
                  Text(
                    'Me: ${me == 1 ? score[0] : score[1]}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Other: ${me == 1 ? score[1] : score[0]}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }
}
