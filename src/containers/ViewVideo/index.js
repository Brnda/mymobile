import React, {Component, PropTypes} from 'react';
import {View, Text, ActivityIndicator} from 'react-native';
import styles from './styles';
import {connect} from 'react-redux';
import * as cameraReducer from '../../reducers/camera/cameraReducer';
import AndroidNativeVideo from '../../components/AndroidNativeVideo';

class ViewVideo extends Component {

  getCameraIDs() {
    return this.props.spaces[this.props.spaceId].camera_ids;
  }

  componentWillMount() {
    if (this.getCameraIDs().length > 0) {
      let firstCameraID = this.getCameraIDs()[0];
      this.props.getCamera(firstCameraID);
    }
  }

  render() {
    let spinner;
    let video;
    let uri;
    if (!this.props.getting && this.props.camera) {
      uri = this.props.camera.cameras[0].streams[0];
    }
    /*
     */
    return (
      <View style={styles.container}>
        <View style={{flexDirection: 'row', alignItems: 'center'}}>
          <Text style={[styles.titleText, {textAlign: 'center', flex: 1}]}>Video!</Text>
        </View>

        <View style={styles.videoContainer}>
          <ActivityIndicator size="large" style={styles.activityIndicator}/>
        </View>
      </View>
    )
  }
}
/*

 {this.props.getting &&
 <ActivityIndicator size="large" style={styles.activityIndicator}/>
 }
 {uri &&
 <AndroidNativeVideo src={uri} style={styles.nativeVideoView}/>
 }
 */


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