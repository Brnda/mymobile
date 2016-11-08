import React, {Component, PropTypes} from 'react';
import {View, Text, AsyncStorage} from 'react-native';
import styles from './styles';
import {connect} from 'react-redux';
import * as cameraReducer from '../../reducers/camera/cameraReducer';
import VideoController from '../../components/VideoController';
import {USER_TOKEN} from '../../lib/constants';

class MyFloor extends Component {

  getCameraIDs() {
    if (this.props.hasOwnProperty('spaceId') && typeof this.props.spaceId !== 'undefined' && this.props.hasOwnProperty('spaces') && typeof this.props.hasOwnProperty('spaces') !== 'undefined' && this.props.spaces.hasOwnProperty(this.props.spaceId)) {
      console.log("Getting camera IDs!");
      return this.props.spaces[this.props.spaceId].camera_ids;
    }
    console.log("*NOT* getting camera IDs! :(");
    return null;
  }

  componentWillMount() {
    console.log("Will mount...");
    if (this.getCameraIDs() && this.getCameraIDs().length > 0) {
      let firstCameraID = this.getCameraIDs()[0];
      console.log("Got camera IDs, and it's not empty! First one is " + firstCameraID + ". Calling getCamera...");
      AsyncStorage.getItem(USER_TOKEN).then((token) => {
        this.props.getCamera(firstCameraID, token);
      });
    }
  }

  render() {
    let uri;
    console.log("Rendering... props:");
    ['getting', 'cameras', 'spaceId'].forEach((x) => console.log(x + ": " + this.props[x]));
    if (!this.props.getting && this.props.camera && this.props.camera.hasOwnProperty('cameras')) {
      console.log("... have 'cameras'...");
      if (this.props.camera.cameras.length > 0 && this.props.camera.cameras[0].hasOwnProperty('streams') && this.props.camera.cameras[0].streams.length > 0) {
        uri = this.props.camera.cameras[0].streams[0];
        console.log("... have URI! It's " + uri);
      }
    }
    let video = <VideoController uri={uri}/>;
    let loading = <Text>Loading...</Text>;
    let no_video = <Text>No video!</Text>;
    let show;
    if (uri) {
      show = video;
    } else {
      if (this.props.getting) {
        show = loading;
      } else {
        show = no_video;
      }
    }
    return (
      <View style={styles.container}>
        {show}
      </View>
    );
  }
}

MyFloor.propTypes = {
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
    getCamera: (cameraId, token) => {
      dispatch(cameraReducer.getCamera(cameraId, token))
    }
  }
};

export default connect(mapStateToProps, mapDispatchToProps)(MyFloor);