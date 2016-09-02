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
    alignSelf: 'center',
  },
  subHeader: {
    flexDirection: 'row',
    marginLeft: 20,
    marginRight: 20,
    marginTop: 20,
    paddingBottom: 8,
    borderColor: '#d6d7da',
    borderBottomWidth: 1
  },
  tenatDataValid: {
    flexDirection: 'row',
    marginLeft: 20,
    marginRight: 20,
    borderColor: '#d6d7da',
    borderTopWidth: 1,
    justifyContent: 'center',
    marginTop: 20,
    paddingTop: 8,
  },
  headerText: {
    color: '#fff',
    fontFamily: 'DINPro',
    fontSize: 26
  },

  subHeaderText: {
    color: '#fff',
    fontFamily: 'DINPro',
    textAlign: 'left',
    fontSize: 13
  },
  somethingWrongTextSmall: {
    color: '#fff',
    fontFamily: 'DINPro',
    fontSize: 12,
    textDecorationLine: 'underline',
  },
  tenantDetailBoldText: {
    color: '#fff',
    fontFamily: 'DINPro-Bold',
    fontSize: 15
  },
  tenantDetailText: {
    color: '#fff',
    fontFamily: 'DINPro',
    fontSize: 15
  },
  tenantDetails: {
    flexDirection: 'column',
    marginTop: 15,
    marginLeft: 20,
    marginRight: 20,
  },
  tenantDetailColumnLeft: {
    alignItems: 'flex-end',
    marginRight: 5,
    flex: 1,
  },
  tenantDetailColumnRight: {
    alignSelf: 'flex-end',
    marginLeft: 5,
    flex: 2,
  },
  tenantDetailsRow: {
    flexDirection: 'row',
  },

  continueButton: {
    borderColor: '#d6d7da',
    borderWidth: 1,
    alignItems: 'center',
    borderRadius: 5,
    position: 'absolute',
    left: 20,
    right: 20,
    bottom: 20
  },

  continueButtonText: {
    color: 'white',
    padding: 20,
    fontFamily: 'DINPro-Bold',
  }
});

export default styles;