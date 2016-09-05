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
    alignSelf: 'center'
  },
  headerText: {
    color: '#fff',
    fontFamily: 'DINPro',
    fontSize: 26
  },
  tenantDetails: {
    flexDirection: 'column',
    marginTop: 50,
    marginLeft: 20,
    marginRight: 20,
  },
  tenantDetailColumnLeft: {
    marginRight: 5,
    flex: 4,
  },
  tenantDetailColumnRight: {
    marginLeft: 5,
    flex: 1,
  },
  tenantDetailsRow: {
    flexDirection: 'row',
  },
  tenantDetailBoldText: {
    color: '#fff',
    fontFamily: 'DINPro-Bold',
    fontSize: 15
  },
  tenantDetailText: {
    color: '#fff',
    fontFamily: 'DINPro',
    fontSize: 14
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