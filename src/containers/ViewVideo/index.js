import React, {Component, PropTypes} from 'react';
import {View, Text} from 'react-native';
import styles from './styles';
import {connect} from 'react-redux';
import * as cameraReducer from '../../reducers/camera/cameraReducer';
import AndroidNativeVideo from '../../components/AndroidNativeVideo';
import * as Progress from 'react-native-progress';

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

  render() {
    let spinner;
    let video;
    let uri;
    if (!this.props.getting && this.props.camera) {
      if (this.props.camera.cameras.length > 0 && this.props.camera.cameras[0].streams.length > 0) {
        uri = this.props.camera.cameras[0].streams[0];
      }
    }
    /*
     */
    return (
      <View style={styles.container}>
        <View style={{flexDirection: 'row', alignItems: 'center'}}>
          <Text style={[styles.titleText, {textAlign: 'center', flex: 1}]}>Video!</Text>
        </View>

        <View style={styles.videoContainer}>
          {this.props.getting &&
            <Progress.Bar indeterminate={true} style={styles.progressView}/>
          }
          {uri &&
            <AndroidNativeVideo src={uri} style={styles.nativeVideoView}/>
          }
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