// Ctrl + shift + B　実行 //

// ライブラリのインポート
import processing.video.*;
import jp.nyatla.nyar4psg.*;

// 変数の宣言 //
Capture camera; // カメラ
MultiMarker[] markers; // マーカー
Character[] characters; // キャラクターの配列変数
int character_num = 4; // キャラクターの数
int attackerIndex = -1; // 攻撃側キャラクターの
int victimIndex = -1; // 被攻撃側キャラクターのインデックス
boolean isAttacking = false; // 攻撃開始フラグ
int attackMarkerIndex = 3; // 攻撃マーカーのインデックス

// キャラクターのクラス //
class Character {
  PShape shape;
  int HP;
  int ATK;
  float scale;
  int maxHP;
  int damage = 0;
  
  Character(String filename, int maxHP, int ATK, float scale) {
    shape = loadShape(filename);
    this.maxHP = maxHP;
    this.HP = maxHP - damage;
    this.ATK = ATK;
    this.scale = scale;
  }
  
  void takeDamage(int damage) {
    this.HP -= damage;
    if (this.HP <= 0){ // 死んだ際にお墓にする
      this.maxHP = 0;
      this.HP = 0;
      this.ATK = 0;
      this.filename = "OBJ.obj";
      this.scale = 0.5;
    }
  }
}

void setup() {
  // ウィンドウ&カメラの設定 //
  size(640, 480, P3D); // ウィンドウのサイズ
  String[] cameras = Capture.list(); // 使用可能カメラの取得
  camera = new Capture(this, cameras[cameras.length - 1]); // カメラを設定
  camera.start(); // カメラ起動
  
  // ARの設定 //
  markers = new MultiMarker[character_num];
  for (int i = 0; i < markers.length; i++) {
    markers[i] = new MultiMarker(this, width, height, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
    markers[i].addNyIdMarker(i, 80); // マーカ登録(ID, マーカの幅)
  }

  // キャラクターの作成 //
  characters = new Character[character_num];
  characters[0] = new Character("greenpepper.obj", 100, 10, 0.2);
  characters[1] = new Character("rocket.obj", 90, 15, 0.3);
  characters[2] = new Character("SubstancePlayerExport.obj", 150, 30, 0.7);
}

void draw() {
  if (camera.available()) {
    camera.read();
    lights();
    
    for (int i = 0; i < markers.length; i++) {
      markers[i].detect(camera);
      markers[i].drawBackground(camera);
      
      if (markers[i].isExist(0)) {
        markers[i].beginTransform(0); // マーカー中心を原点に設定
        
        // キャラクター //
        if (i < character_num) {
          pushMatrix();
          scale(characters[i].scale);
          rotateX(PI / 2);
          shape(characters[i].shape);
          popMatrix();
          
          // HPの表示 //
          int textSize = 60;
          pushMatrix();
          translate(-textSize/2, 0, 100);
          textMode(SHAPE);
          textSize(textSize);
          rotateX(- PI / 2);
          fill(255);
          text(characters[i].HP, 0, 0); 
          popMatrix();
        }

        fill(255); // 初期化
        
        markers[i].endTransform(); // マーカー中心を原点から解除
        
        // 攻撃マーカーが認識されたら、直前のキャラクターマーカーが攻撃を行います。
        if (i == attackMarkerIndex && attackerIndex >= 0) {
          isAttacking = true;
        }
      } else {
        // マーカーが認識されなかったら、攻撃者のインデックスをリセットします。
        if (i == attackerIndex) {
          attackerIndex = -1;
        }
      }
    }

    if (isAttacking) {
      characters[victimIndex].takeDamage(characters[attackerIndex].ATK);
      isAttacking = false;
      attackerIndex = -1;
    }
  }
}

void keyReleased() {
  if (key == 'a') {
    String victim = prompt("被攻撃者の番号を入力してください(0~2): ");
    victimIndex = Integer.parseInt(victim);
  }
}

// ダイアログで数字を入力するための関数
String prompt(String message) {
  return javax.swing.JOptionPane.showInputDialog(message);
}
