package io.owal.android;


import android.annotation.TargetApi;
import android.content.Context;
import android.net.Uri;
import android.os.Build;
import android.support.annotation.Nullable;
import android.util.AttributeSet;
import android.view.View;
import android.widget.VideoView;

import com.facebook.react.uimanager.annotations.ReactProp;

import java.lang.annotation.Target;

public class AndroidNativeVideoViewer extends View {
  private Context mContext;
  private String source;
  VideoView videoView;

  public AndroidNativeVideoViewer(Context context) {
    super(context);
    videoView = new VideoView(context);
  }

  public void setSource(String source) {
    this.source = source;
    videoView.setVideoURI(Uri.parse(source));
    videoView.requestFocus();
    videoView.start();
  }

}
