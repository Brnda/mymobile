import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#272727',
    flexDirection: 'column',
    justifyContent: 'center'
  },
  logo: {
    width: 105,
    height: 105,
    marginTop: 0,
    alignSelf: 'center',
    marginBottom: 0
  },
  header: {
    alignSelf: 'center'
  },
  headerText: {
    color: '#fff',
    fontFamily: 'DINPro',
    fontSize: 36
  }
});

export default styles;