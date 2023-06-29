// ctrl + shift + b 実行

// ライブラリのインポート
import processing.video.*;
import jp.nyatla.nyar4psg.*;

// 変数の宣言 //
Capture camera; // カメラ
MultiMarker[] markers; // マーカー
Character[] characters; // キャラクターの配列変数
int character_num = 3; // キャラクターの数

// キャラクターのクラス //
class Character {
  PShape shape;
  int HP;
  int ATK;
  float scale;
  
  Character(String filename, int HP, int ATK, float scale) {
    shape = loadShape(filename);
    this.HP = HP;
    this.ATK = ATK;
    this.scale = scale;
  }
 
}

void setup() {
  // ウィンドウ&カメラの設定 //
  size(640, 480, P3D); // ウィンドウのサイズ
  String[] cameras = Capture.list(); // 使用可能カメラの取得
  camera = new Capture(this, cameras[0]); // ウェブカメラを設定
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
  characters[1] = new Character("rocket.obj", 100, 10, 0.3);
  characters[2] = new Character("SubstancePlayerExport.obj", 100, 10, 0.5);
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
        pushMatrix();
        scale(characters[i].scale);
        rotateX(PI / 2);
        shape(characters[i].shape);
        popMatrix();
        
        // HPゲージ //
        pushMatrix();
        translate(0, 0, 100); // オブジェクトの上にHPゲージを配置するための変換
        fill(0, 255, 0); // HPゲージを緑色に
        float hpBarLength = map(characters[i].HP, 0, 100, 0, 50); // HPの値に基づいてHPゲージの長さを計算
        box(hpBarLength, 5, 5); // HPゲージを描画
        popMatrix();
        fill(255);
        
        markers[i].endTransform();// マーカー中心を原点から解除
        
      }
    }
  }
}
