import React, {Component, PropTypes} from 'react';
import {View, Text} from 'react-native';
import styles from './styles';
import {connect} from 'react-redux';
import * as cameraReducer from '../../reducers/camera/cameraReducer';
import SendIntent from 'react-native-send-intent';

class ViewVideo extends Component {

  getCameraIDs() {
    return this.props.spaces[this.props.spaceId].camera_ids;
  }

  componentWillMount() {
    console.log("ViewVideo will mount!");
    if (this.getCameraIDs().length > 0) {
      let firstCameraID = this.getCameraIDs()[0];
      console.log("First camera ID: " + firstCameraID);
      this.props.getCamera(firstCameraID);
    }
    else {
      console.log("No cameras :(");
    }
  }

  componentDidUpdate() {
    console.log("Component did receive props");
    console.log("Camera: " + this.props.camera);
    if (this.props.camera) {
      console.log("Component has camera");
      const uri = this.props.camera.cameras[0].streams[0];
      if (uri) {
        console.log("Component has URI");
        SendIntent.sendRawIntent("android.intent.action.VIEW", uri);
      }
    }
  }

  render() {
    let spinner;
    let video;
    if (this.props.getting) {
      spinner = <Text>Please wait...</Text>;
    } else {
      if (!this.props.camera) {
        console.log("Wah");
        video = <Text>wah</Text>
      } else {
        video = <Text>{JSON.stringify(this.props.camera, null, 2)}</Text>
      }
    }
    return (
      <View style={styles.container}>
        {spinner}
        <Text>Video!</Text>

        <Text>{JSON.stringify(this.getCameraIDs(), null, 2)}</Text>
        {video}
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