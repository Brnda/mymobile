import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFF',
    flexDirection: 'column',
    justifyContent: 'center'
  },
  titleText: {
    fontSize: 30
  },
  spinner: {
    height: 300,
    width: 300,
    alignSelf: 'center'
  },
  videoContainer: {
    flexDirection: 'row',
    flex: 1
  },
  nativeVideoView: {
    height: 270,
    flex: 1
  }
});

export default styles;