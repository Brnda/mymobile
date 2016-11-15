import React, {Component, PropTypes} from 'react';
import {View, Text, ActivityIndicator, Platform} from 'react-native';
import styles from './styles';
import {connect} from 'react-redux';
import * as cameraReducer from '../../reducers/camera/cameraReducer';
import AndroidNativeVideo from '../../components/AndroidNativeVideo';
import IOSVideoController from '../../components/IOSVideoController';

class ViewVideo extends Component {

  getCameraIDs() {
    if (this.props.hasOwnProperty('spaceId') && typeof this.props.spaceId !== 'undefined' && this.props.hasOwnProperty('spaces') && typeof this.props.hasOwnProperty('spaces') !== 'undefined' && this.props.spaces.hasOwnProperty(this.props.spaceId)) {
      return this.props.spaces[this.props.spaceId].camera_ids;
    }
    return null;
  }

  componentWillMount() {
    if (this.getCameraIDs() && this.getCameraIDs().length > 0) {
      let firstCameraID = this.getCameraIDs()[0];
      this.props.getCamera(firstCameraID);
    }
  }

  getTitle() {
    let spaceId = this.props.spaceId;
    if (spaceId && this.props.spaces && this.props.spaces.hasOwnProperty(spaceId) && this.props.spaces[spaceId].name) {
      return this.props.spaces[spaceId].name;
    }
    return "Video";
  }

  render() {
    let spinner;
    let video;
    let uri;
    if (!this.props.getting && this.props.camera && this.props.camera.hasOwnProperty('cameras')) {
      if (this.props.camera.cameras.length > 0 && this.props.camera.cameras[0].hasOwnProperty('streams') && this.props.camera.cameras[0].streams.length > 0) {
        uri = this.props.camera.cameras[0].streams[0];
      }
    }
    let title = this.getTitle();
    let player;
    if (Platform.OS === 'ios') {
      player = <IOSVideoController style={styles.nativeVideoView}/>;
      var VideoControllerManager = require('NativeModules').VideoControllerManager;
      VideoControllerManager.setURI(uri);
    } else {
      player = <AndroidNativeVideo style={styles.nativeVideoView} uri={uri}/>
    }
    let no_video;
    if (!this.props.getting && !uri) {
      no_video = <Text>Video not available</Text>;
    }
    return (
      <View style={styles.container}>
        <View style={{flexDirection: 'row', alignItems: 'center'}}>
          <Text style={[styles.titleText, {textAlign: 'center', flex: 1}]}>{title}</Text>
        </View>

        <View style={styles.videoContainer}>
          {this.props.getting &&
            <ActivityIndicator size="large" style={styles.activityIndicator}/>
          }
          {uri &&
            player
          }
          {no_video}
        </View>
      </View>
    )
  }
}

ViewVideo.propTypes = {
  spaceId: PropTypes.string.isRequired,
  spaces: PropTypes.object.isRequired,
  getting: PropTypes.bool.isRequired,
  camera: PropTypes.object
};

function mapStateToProps(state) {
  return {
    spaceId: state.spaces.get('SPACE_ID'),
    spaces: state.spaces.get('SPACES'),
    camera: state.camera.get('CAMERA'),
    getting: state.camera.get('GETTING')
  }
}

const mapDispatchToProps = (dispatch) => {
  return {
    getCamera: (cameraId) => {
      dispatch(cameraReducer.getCamera(cameraId))
    }
  }
};

export default connect(mapStateToProps, mapDispatchToProps)(ViewVideo);