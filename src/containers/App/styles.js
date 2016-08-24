import { StyleSheet } from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: 'center',
    backgroundColor: '#272727'
  },

  logo: {
    width: 175,
    height: 68,
    marginTop: 100
  },

  messageBox: {
    backgroundColor: '#1e9e6b',
    width: 300,
    paddingTop: 10,
    paddingBottom: 20,
    paddingLeft: 20,
    paddingRight: 20,
    borderRadius: 7
  },

  messageBoxContainer: {
    justifyContent: 'center',
    flexDirection: 'row',
    position: 'absolute',
    bottom: 300,
    left: 0,
    right: 0
  },

  messageBoxTitleText: {
    fontFamily: 'Lato-Regular',
    fontSize: 18,
    color: '#fff',
    textAlign: 'center',
    marginBottom: 10
  },
  messageBoxBodyText: {
    color: '#fff',
    fontFamily: 'Lato-Regular',
    textAlign: 'center',
    fontSize: 18
  },
  choiceBoxes: {
    flexDirection: 'row',
    justifyContent: 'center',
    position: 'absolute',
    bottom: 150,
    left: 0,
    right: 0,
  },
  choiceBox: {
    backgroundColor: 'white',
    borderColor: 'black',
    borderStyle: 'solid',
    borderWidth: 2,
    padding: 20,
    marginLeft: 5,
    marginRight: 5,
    borderRadius: 7
  },
  touchable: {}
});

export default styles;