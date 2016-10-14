import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    backgroundColor: '#272727',
    flexDirection: 'column',
    flex: 1
  },
  header: {
    justifyContent: 'flex-start',
    alignSelf: 'center',
    marginLeft: 10,
    marginRight: 10
  },
  headerText: {
    color: '#fff',
    fontFamily: 'DINPro',
    fontSize: 20
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
    marginTop: 20
  },
  tenantButton: {
    margin: 12,
  },
  tenantButtonText: {
    alignSelf: 'center',
    color: 'white',
    paddingTop: 20,
    paddingBottom: 20,
    fontFamily: 'DINPro',
    textDecorationLine: "underline",
    lineHeight: 20
  },
  tenantSkipButton: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center'
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
    paddingTop: 20,
    paddingBottom: 20,
    fontFamily: 'DINPro-Bold',
  },
});

export default styles;
