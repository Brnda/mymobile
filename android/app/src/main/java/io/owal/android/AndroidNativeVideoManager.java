package io.owal.android;

import android.app.Activity;
import android.net.Uri;
import android.support.annotation.Nullable;
import android.util.Log;
import android.widget.VideoView;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

public class AndroidNativeVideoManager extends SimpleViewManager<VideoView> {

  private static final String TAG = AndroidNativeVideoManager.class.getSimpleName();

  @Override
  public String getName() {
    return "RCTAndroidNativeVideo";
  }

  @Override
  protected VideoView createViewInstance(ThemedReactContext reactContext) {
    Log.i(TAG, "Creating new view instance!");
    return new VideoView(reactContext);
  }

  @ReactProp(name = "src")
  public void setSrc(VideoView view, @Nullable String src) {
    Log.i(TAG, "Setting src: " + src);
    Log.d(TAG, "wxh:" + view.getWidth() + " x " + view.getHeight());
    if (view.isPlaying()) {
      view.stopPlayback();
    }
    view.setVideoURI(Uri.parse(src));
    view.requestFocus();
    view.start();
  }
}
