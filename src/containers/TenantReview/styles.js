import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#272727',
    flexDirection: 'column'
  },
  header: {
    justifyContent: 'flex-start',
    alignSelf: 'center',
  },
  headerText: {
    color: '#fff',
    fontFamily: 'DINPro',
    fontSize: 26
  },
  tenantDetailText: {
    color: '#fff',
    fontFamily: 'DINPro',
    fontSize: 15
  },
  tenantAddressDetails: {
    flex: 3,
    flexDirection: 'column',
    alignItems: 'center',
    justifyContent: 'center'
  },
  tenantAddressButtons: {
    flex: 1,
    flexDirection: 'row',
    alignItems: 'flex-end',
  },
  tenantButton: {
    flex:1,
    borderColor: '#d6d7da',
    borderWidth: 1,
    alignItems: 'center',
    borderRadius: 5,
    margin: 12
  },
  tenantButtonText: {
    alignSelf: 'center',
    color: 'white',
    paddingTop: 20,
    paddingBottom: 20,
    fontFamily: 'DINPro-Bold',
  }
});

export default styles;