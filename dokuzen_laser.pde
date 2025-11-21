int W, H; // 画面サイズは fullScreen() に合わせる

PGraphics metalTex;

// ---------------- パラメータ群 ----------------
float glowIntensity      = 1.0;   // 赤熱グローの強さ
float highlightIntensity = 0.7;   // ハイライトの強さ
float dentDepth          = 0.35;  // 凹み陰影の強さ

int maxTrailPoints       = 500;   // 融解点の上限
float brushRadius        = 20;    // 融解点の半径
float hoverDelaySec      = 0.001; // 同じ座標に留まる必要時間（秒）
float moveThreshold      = 20.0;  // 「動いた」とみなす距離（px）

// ★ マウス座標オフセット（矢印キーで変更可能）
int offsetXParam         = 100;   // 右方向オフセット(px)
int offsetYParam         = 0;   // 上方向オフセット(px)

// ---------------- 状態管理 ----------------
ArrayList<PVector> meltPoints = new ArrayList<PVector>();
float hoverDuration = 0;   // 現在の座標に留まっている時間
int lastX, lastY;          // 前回の座標

void settings() {
  fullScreen(P2D); // メインディスプレイでフルスクリーン
}

void setup() {
  surface.setTitle("Laser melt plate fullscreen offset with arrow keys");
  noStroke();
  noCursor(); // カーソル非表示

  W = displayWidth;
  H = displayHeight;

  metalTex = createGraphics(W, H, P2D);
  genMetalTexture();

  lastX = mouseX;
  lastY = mouseY;
}

void draw() {
  float dt = min(0.05, 1.0 / max(frameRate, 1));

  // 背景鉄板を毎フレーム描画
  image(metalTex, 0, 0);

  // マウス座標にオフセットを適用
  int offsetX = mouseX + offsetXParam;   // 右方向オフセット
  int offsetY = mouseY - offsetYParam;   // 上方向オフセット
  offsetX = max(0, min(W-1, offsetX));
  offsetY = max(0, min(H-1, offsetY));

  // マウスが鉄板上にあるか判定
  boolean onPlate = (offsetX >= 0 && offsetX < W && offsetY >= 0 && offsetY < H);

  if (onPlate) {
    float d = dist(offsetX, offsetY, lastX, lastY);

    if (d < moveThreshold) {
      hoverDuration += dt;
      if (hoverDuration >= hoverDelaySec) {
        meltPoints.add(new PVector(offsetX, offsetY));
        if (meltPoints.size() > maxTrailPoints) {
          meltPoints.remove(0);
        }
        hoverDuration = 0;
      }
    } else {
      hoverDuration = 0;
    }
  } else {
    hoverDuration = 0;
  }

  lastX = offsetX;
  lastY = offsetY;

  // 融解点を描画
  loadPixels();
  for (PVector p : meltPoints) {
    int cx = int(p.x);
    int cy = int(p.y);
    for (int y = max(0, cy-int(brushRadius)); y < min(H, cy+int(brushRadius)); y++) {
      for (int x = max(0, cx-int(brushRadius)); x < min(W, cx+int(brushRadius)); x++) {
        float d = dist(x, y, cx, cy);
        if (d < brushRadius) {
          int idx = y * W + x;
          float t = 1.0 - d/brushRadius;
          color base = pixels[idx];

          float glow = 0.35 * glowIntensity * t;
          color glowCol = color(
            255 * (0.7 + 0.3 * t),
            120 * (1.0 - t),
            0
          );
          color c1 = blendAdd(base, glowCol, glow);

          float hl = 0.12 * highlightIntensity * t;
          color c2 = blendAdd(c1, color(255), hl);

          float shade = 0.10 * dentDepth * t;
          color c3 = lerpColor(c2, color(0), shade);

          pixels[idx] = c3;
        }
      }
    }
  }
  updatePixels();
}

// 矢印キーでオフセット値を変更
void keyPressed() {
  if (keyCode == LEFT) {
    offsetXParam -= 10; // 左キーで右方向オフセットを減らす
  } else if (keyCode == RIGHT) {
    offsetXParam += 10; // 右キーで右方向オフセットを増やす
  } else if (keyCode == UP) {
    offsetYParam += 10; // 上キーで上方向オフセットを増やす
  } else if (keyCode == DOWN) {
    offsetYParam -= 10; // 下キーで上方向オフセットを減らす
  }
}

// 加算ブレンド
color blendAdd(color a, color b, float alpha) {
  float r = red(a)   + red(b)   * alpha;
  float g = green(a) + green(b) * alpha;
  float bl= blue(a)  + blue(b)  * alpha;
  return color(constrain(r,0,255), constrain(g,0,255), constrain(bl,0,255));
}

// 金属テクスチャ生成
void genMetalTexture() {
  metalTex.beginDraw();
  metalTex.noStroke();
  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      float n = 35 + random(20);
      metalTex.set(x, y, color(n));
    }
  }
  metalTex.loadPixels();
  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      float u = (x + y) / float(W + H);
      float a = lerp(70, 40, u);
      color base = metalTex.pixels[y*W + x];
      metalTex.pixels[y*W + x] = lerpColor(base, color(a), 0.6);
    }
  }
  metalTex.updatePixels();
  metalTex.fill(255, 10);
  for (int y = 0; y < H; y += 2) {
    metalTex.rect(0, y, W, 1);
  }
  metalTex.endDraw();
}
