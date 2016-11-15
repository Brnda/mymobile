import React, {Component} from 'react';
import { View, requireNativeComponent, NativeModules, NativeEventEmitter } from 'react-native';
import Orientation from 'react-native-orientation';
import {Actions} from 'react-native-router-flux';

const myModuleEvt = new NativeEventEmitter(NativeModules.EventNotificationCenter);
myModuleEvt.addListener('closeVideoManager', (data) => {
    Orientation.lockToPortrait();
    Actions.pop()
    });

class IOSVideoController extends Component {

  componentDidMount() {
    Orientation.unlockAllOrientations();
  }

  render() {
    return <VideoControllerz {...this.props}/>;
  }
}

IOSVideoController.propTypes = {
};

var VideoControllerz = requireNativeComponent('VideoController', IOSVideoController);

export default IOSVideoController;