import React, {Component, PropTypes} from 'react';
import {View, Text} from 'react-native';
import styles from './styles';
import {connect} from 'react-redux';
import * as cameraReducer from '../../reducers/camera/cameraReducer';
import AndroidNativeVideo from '../../components/AndroidNativeVideo';

class ViewVideo extends Component {

  getCameraIDs() {
    let spaceId = this.props.spaceId;
    let spaces = this.props.spaces;
    console.log("spaces=" + JSON.stringify(this.props.spaces));
    console.log("spaceId=" + spaceId);
    let space = spaces[spaceId];
    let cameraIDs = space.camera_ids;
    return cameraIDs;
//    return this.props.spaces[this.props.spaceId].camera_ids;
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
    if (this.props.getting) {
      spinner = <Text>Please wait...</Text>;
    } else {
      if (this.props.camera) {
        const uri = this.props.camera.cameras[0].streams[0];
        if (uri) {
          console.log("Loadingi video! uri=" + uri);
          video = <AndroidNativeVideo src={uri} style={styles.nativeVideoView} />
        }
      }
    }
    return (
      <View style={styles.container}>
        {spinner}
        <Text>Video!</Text>
        <View style={styles.videoContainer}>
        {video}
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