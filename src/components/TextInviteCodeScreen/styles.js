import { StyleSheet } from 'react-native'

const styles = StyleSheet.create({

  rectangleContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: 'transparent',
  },

  rectangle: {
    height: 250,
    width: 250,
    borderWidth: 2,
    borderColor: '#00FF00',
    backgroundColor: 'transparent',
  },

  container: {
    flex: 1,
    alignItems: 'center',
    backgroundColor: '#272727'
  },

  logo: {
    width: 175,
    height: 68,
    marginTop: 20
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
    //position: 'absolute',
    marginTop: 20,
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
  inputcontainer: {
      marginTop: 5,
      padding: 10,
      flexDirection: 'row'
    },
    enterButton: {
      flexDirection: 'row',
      justifyContent: 'center',
      backgroundColor: 'white',
      borderRadius: 3,
      padding: 15,
      width: 100
      //height: 36,
    },
    enterButtonText: {
      fontSize: 17,
      fontWeight: '500',
      color: '#0097CE',
      //marginTop: 6,
    },

      cancelButton: {
        flexDirection: 'row',
        justifyContent: 'center',
        backgroundColor: 'white',
        borderRadius: 3,
        padding: 15,
        width: 100,
        marginTop: 10,
      },
      cancelButtonText: {
        fontSize: 17,
        fontWeight: '500',
        color: '#0097CE',
      },
    input: {
      height: 36,
      padding: 4,
      marginRight: 5,
      flex: 4,
      fontSize: 18,
      borderWidth: 1,
      borderColor: '#48afdb',
      borderRadius: 4,
      color: '#48BBEC'
    },
});

export default styles;
