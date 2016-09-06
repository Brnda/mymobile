import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#272727',
    flexDirection: 'column'
  },
  logo: {
    width: 65,
    height: 65,
    marginTop: 50,
    marginBottom: 35,
    alignSelf: 'center'
  },
  header: {
    justifyContent: 'flex-start',
    alignSelf: 'flex-start',
    marginLeft: 20,
    marginRight: 20,
  },
  headerText: {
    color: '#fff',
    fontFamily: 'DINPro',
    fontSize: 26
  },
  inviteTextInput: {
    height: 40,
    color: 'white',
    paddingRight: 8,
    paddingLeft: 8,
  },
  containerInputText: {
    borderWidth: 1,
    borderBottomColor: 'white',
    borderTopColor: '#272727',
    borderLeftColor: '#272727',
    borderRightColor: '#272727',
    marginLeft: 20,
    marginRight: 20,
  },
  continueButton: {
    borderColor: '#d6d7da',
    borderWidth: 1,
    alignItems: 'center',
    borderRadius: 5,
    marginTop: 32,
    marginLeft: 20,
    marginRight: 20,
  },

  continueButtonText: {
    color: 'white',
    padding: 20,
    fontFamily: 'DINPro-Bold',
  }
});

export default styles;