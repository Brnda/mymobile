package io.owal.android;

import android.app.Activity;
import android.support.annotation.Nullable;

import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;

public class AndroidNativeVideoViewerManager extends SimpleViewManager<AndroidNativeVideoViewer> {
  private final Activity mActivity;

  @Override
  public String getName() {
    return "RCTAndroidNativeVideoViewer";
  }

  public AndroidNativeVideoViewerManager(Activity activity) {
    mActivity = activity;
  }

  @Override
  protected AndroidNativeVideoViewer createViewInstance(ThemedReactContext reactContext) {
    return new AndroidNativeVideoViewer(reactContext);
  }

  @ReactProp(name = "src")
  public void setSrc(AndroidNativeVideoViewer view, @Nullable String src) {
    view.setSource(src);
  }
}
