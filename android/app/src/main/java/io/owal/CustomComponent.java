package io.owal;

import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;

/**
 * Created by matzero on 2016-07-19.
 */
public class CustomComponent extends ReactContextBaseJavaModule {
    public CustomComponent(ReactApplicationContext reactContext) {
        super(reactContext);
    }

    @Override
    public String getName() {
        return "CustomComponent";
    }

    @ReactMethod
    public void writeFile(String fileName, String content, Callback error, Callback success) {
        success.invoke("Hi there!");
    }
}
