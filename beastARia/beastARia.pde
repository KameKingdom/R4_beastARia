// ライブラリのインポート
import processing.video.*;
import jp.nyatla.nyar4psg.*;
import processing.sound.*; 

SoundFile bgm;
SoundFile attackSound;

// 変数の宣言 //
Capture camera; // カメラ
MultiMarker[] markers; // マーカー

Character[] cards; // キャラクターの配列変数
int character_num = 3; // キャラクターの数
int cards_num = character_num + 1 + 1 + 1;

int playerIndex = -1;
int enemyIndex = character_num; // 敵のモンスターのインデックス
int checkStatusIndex = enemyIndex + 1; // ステータス確認用マーカーのインデックス
int attackMarkerIndex = checkStatusIndex + 1; // 攻撃用マーカーのインデックス

boolean isAttacking = false; // 攻撃フラグ
boolean isCheckingStatus = false; // ステータス確認フラグ
boolean isFinished = false; // 終了フラグ

int turn = 1;
String[] enemyMonsterFiles = {"greenpepper.obj", "rocket.obj", "SubstancePlayerExport.obj"}; // 敵モンスターのファイル名
String message = "Message Box !!";
// 初期設定 //
void setup() {
  // ウィンドウ&カメラの設定 //
  size(640, 480, P3D); // ウィンドウのサイズ
  String[] cameras = Capture.list(); // 使用可能カメラの取得
  camera = new Capture(this, cameras[cameras.length - 1]); // カメラを設定
  camera.start(); // カメラ起動

  // 効果音設定 //
  bgm = new SoundFile(this, "sound/bgm.wav");
  bgm.loop();
  attackSound = new SoundFile(this, "sound/attack.wav");
  
  // ARの設定 //
  int marker_num = 10;
  markers = new MultiMarker[marker_num];
  for (int i = 0; i < marker_num; i++) {
    markers[i] = new MultiMarker(this, width, height, "camera_para.dat", NyAR4PsgConfig.CONFIG_PSG);
    markers[i].addNyIdMarker(i, 80); // マーカ登録(ID, マーカの幅)
  }

  // キャラクターの作成 //
  cards = new Character[cards_num];
  cards[0] = new Character("greenpepper.obj"); // 自陣モンスターを設定
  cards[1] = new Character("rocket.obj");
  cards[2] = new Character("SubstancePlayerExport.obj");
  cards[enemyIndex] = null; // 敵陣モンスターの初期化
  cards[checkStatusIndex] = null; // ステータス確認マーカー
  cards[attackMarkerIndex] = null; // 攻撃用マーカー
}

// キャラクターのクラス //
class Character {
  PShape shape;
  String name;
  int HP;
  int ATK;
  float scale;
  float angle = 0.0; // 角度
  int height = 0; // 高度
  ParticleSystem ps; // エフェクト

  // 動きに関するパラメータ //
  
  float rotate_value = 0.0;
  int updown_value = 0;

  Character(String filename) {
    shape = loadShape(filename);
    ps = new ParticleSystem(100, new PVector(0, 0));
    setParameter(filename);
  }

  void setParameter(String filename){
    if(filename.equals("greenpepper.obj")){ this.name = "GreenPepper"; this.HP = 100; this.ATK = 10; this.scale = 0.2; this.rotate_value = 0.05;}
    else if(filename.equals("rocket.obj")){ this.name = "Rocket"; this.HP = 90; this.ATK = 15; this.scale = 0.3; this.rotate_value = 0.05;}
    else if(filename.equals("SubstancePlayerExport.obj")){ this.name = "Plane"; this.HP = 150; this.ATK = 30; this.scale = 0.7; this.updown_value = 1; }
    else{this.name = "unknown"; this.HP = 0; this.ATK = 0; this.scale = 0;}
  }
  
  void takeDamage(int damage) {
    this.HP -= damage;
    if (this.HP <= 0){ // 死んだ際にお墓にする
      shape = loadShape("OBJ.obj");
      this.HP = 0;
      this.ATK = 0;
      this.scale = 0.5;
      this.angle = 0.0;
      this.height = 0;
      this.rotate_value = 0.0;
      this.updown_value = 0;
    }
    runParticleSystem(); // Damage taken so run particle system
  }


  void runParticleSystem() { ps.run(); }

  void move(){
    if(this.height < 10){ this.updown_value = abs(this.updown_value);}
    if(this.height > 50){ this.updown_value = - abs(this.updown_value);}
    this.angle += this.rotate_value;
    this.height += this.updown_value;
  }
}

class Particle {
  PVector position;
  PVector velocity;
  PVector acceleration;
  float lifespan;
  
  Particle(PVector l) {
    acceleration = new PVector(0, 0.05);
    velocity = new PVector(random(-1, 1), random(-2, 0));
    position = l.get();
    lifespan = 100.0;
  }
  
  void run() {
    update();
    display();
  }
  
  void update() {
    velocity.add(acceleration);
    position.add(velocity);
    lifespan -= 2.0;
  }
  
  void display() {
    stroke(255, lifespan);
    fill(255, 0, 0, lifespan);  // Fill red color for particles
    ellipse(position.x, position.y, 8, 8);
  }
  
  boolean isDead() {
    return lifespan < 0;
  }
}

class ParticleSystem {
  ArrayList<Particle> particles;
  PVector origin;
  
  ParticleSystem(int num, PVector v) {
    particles = new ArrayList<Particle>();
    origin = v.get();
    for (int i = 0; i < num; i++) {
      particles.add(new Particle(origin));
    }
  }
  
  void addParticle() {
    particles.add(new Particle(origin));
  }
  
  void run() {
    for (int i = particles.size()-1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.run();
      if (p.isDead()) {
        particles.remove(i);
      }
    }
  }
}


void draw() {
  if (camera.available()) {
    camera.read();
    lights();

    // メッセージボックスの描画
    fill(220);
    stroke(0);
    rect(0, 0, 640, 40); // 上
    rect(0, 400, 640, 80); // 下

    fill(0);
    textSize(24);
    text("turn " + turn, (width - textWidth("turn " + turn)) / 2, 27);
    text(message, (width - textWidth(message)) / 2, 445);
      
    for (int i = 0; i < markers.length; i++) {
      markers[i].detect(camera);
      markers[i].drawBackground(camera);
      
      if (markers[i].isExist(0)) {
        markers[i].beginTransform(0); // マーカー中心を原点に設定
        
        // キャラクター //
        if (i <= character_num && cards[i] != null) {
          cards[i].move();
          pushMatrix();
          translate(0, 0, cards[i].height);
          scale(cards[i].scale);
          rotateX(PI / 2);
          rotateY(cards[i].angle);
          shape(cards[i].shape);
          popMatrix();

          cards[i].runParticleSystem();

          // HPの表示 //
          if (i == enemyIndex) { // Only show HP for enemy
            int textSize = 60;
            pushMatrix();
            translate(-textSize/2, 0, 100);
            textMode(SHAPE);
            textSize(textSize);
            rotateX(- PI / 2);
            fill(255);
            text(cards[i].HP, 0, 0); 
            popMatrix();
          }
          else{
            playerIndex = i;
          }

        }

        fill(255); // 初期化

        // ステータス確認マーカーが認識されたら、ステータスを表示します。
        if (i == checkStatusIndex && playerIndex != -1) {
          isCheckingStatus = true;
          int textSize = 30;
          pushMatrix();
          translate(-textSize/2, 0, 150);
          textMode(SHAPE);
          textSize(textSize);
          rotateX(- PI / 2);
          fill(255);
          text(cards[playerIndex].name + "\nHP: " + cards[playerIndex].HP + "\nATK: " + cards[playerIndex].ATK, 0, 0); 
          popMatrix();
          isCheckingStatus = false;
        }
        markers[i].endTransform(); // マーカー中心を原点から解除
      }
    }
    
    if (cards[enemyIndex] == null) {
      int randomIndex = (int) random(0, enemyMonsterFiles.length);
      cards[enemyIndex] = new Character(enemyMonsterFiles[randomIndex]);
    }
    if (isAttacking) { // 攻撃
      isAttacking = false;
      cards[enemyIndex].takeDamage(cards[playerIndex].ATK);
      cards[playerIndex].takeDamage(cards[enemyIndex].ATK);
    }
    if (playerIndex != -1 || (cards[enemyIndex].HP == 0)){ // 結果表示
      if (cards[enemyIndex].HP == 0){
        message = "You WIN !!";
      }
      else if (cards[playerIndex].HP == 0){
        message = "You cannot give up yet...";
      }
    }
  }
}

void keyReleased() {
  if (key == 'a') {
    attackSound.play();
    isAttacking = true;
    isFinished = false;
    if (playerIndex != -1) {  // Check if player index has been set
      cards[playerIndex].runParticleSystem(); // Run particle system on attack
    }
    turn += 1;
    message = "You attack the monster!";
  }
  if (key == 'q'){
    exit();
  }
}


// ダイアログで数字を入力するための関数
String showPrompt(String message) {
  return javax.swing.JOptionPane.showInputDialog(message);
}

// ダイアログでメッセージを表示する関数
void showMessage(String message) {
  javax.swing.JOptionPane.showMessageDialog(null, message);
}
