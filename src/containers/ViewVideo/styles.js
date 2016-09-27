import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFF',
    flexDirection: 'column',
  },
  videoContainer: {
    height: 500,
    flexDirection: 'row'
  },
  nativeVideoView: {
    width: 360,
    height: 270
  }
});

export default styles;