import React, {Component} from 'react';
import { requireNativeComponent } from 'react-native';
import Orientation from 'react-native-orientation';

class VideoController extends Component {

  componentDidMount() {
    Orientation.unlockAllOrientations();
  }

  render() {
    return <VideoControllerz {...this.props}/>;
  }
}

VideoController.propTypes = {
};

var VideoControllerz = requireNativeComponent('VideoController', VideoController);

export default VideoController;

