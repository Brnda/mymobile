import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    margin: 5,
    alignItems: 'center',
    justifyContent: 'center',
    borderColor: 'black',
    borderStyle: 'solid',
    borderBottomWidth: 1
  },
  text: {
    fontSize: 20
  },
  icon: {
    height: 40,
    width: 40,
    resizeMode: 'contain'
  },
  statusText: {
    fontSize: 10,
    fontWeight: 'bold',
    fontFamily: 'DINPro-Bold'
  },
  progressBar: {
    marginTop: 5,
    marginBottom: 5
  }
});

export default styles;
