import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    backgroundColor: '#272727',
  },

  logo: {
    width: 75,
    height: 75,
    marginTop: 50
  },

  messageBoxContainer: {
    justifyContent: 'center',
    flexDirection: 'column',
    height: 200
  },

  messageBoxBodyText: {
    color: '#fff',
    fontFamily: 'DINPro',
    textAlign: 'left',
    fontSize: 22
  },
  touchable: {}
});

export default styles;
