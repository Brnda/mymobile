import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFF',
    flexDirection: 'column',
  },
  header: {
    backgroundColor: 'white',
    alignItems: 'center',
    marginTop: 50
  },
  headerText: {
    fontSize: 30
  },
  row: {
    backgroundColor: 'white',
    margin: 10,
    flexDirection: 'row',
    flex: 1
  }
});

export default styles;