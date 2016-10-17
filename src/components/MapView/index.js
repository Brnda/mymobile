import React, {Component} from 'react';
import { requireNativeComponent } from 'react-native';

class VideoController extends Component {
  render() {
    const xx =  <VideoControllerz {...this.props}/>;
    console.log(`VideoControllerz ${xx}`)
    return xx;
  }
}

VideoController.propTypes = {
};

var VideoControllerz = requireNativeComponent('VideoController', VideoController);

export default VideoController;

