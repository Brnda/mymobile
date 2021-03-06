package io.owal.android;

import android.net.Uri;
import android.support.annotation.Nullable;
import android.widget.VideoView;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

public class AndroidNativeVideoManager extends SimpleViewManager<VideoView> {


  @Override
  public String getName() {
    return "RCTAndroidNativeVideo";
  }

  @Override
  protected VideoView createViewInstance(ThemedReactContext reactContext) {
    return new VideoView(reactContext);
  }

  @ReactProp(name = "src")
  public void setSrc(VideoView view, @Nullable String src) {
    if (view.isPlaying()) {
      view.stopPlayback();
    }
    view.setVideoURI(Uri.parse(src));
    view.requestFocus();
    view.start();
  }
}
