import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#FFF',
    flexDirection: 'column',
    marginBottom: 55
  },
  header: {
    backgroundColor: 'white',
    alignItems: 'center',
    marginTop: 10,
    borderColor: 'black',
    borderStyle: 'solid',
    borderBottomWidth: 1,
    marginLeft: 5,
    marginRight: 5,
    paddingTop: 6,
    paddingBottom: 6
  },
  headerText: {
    fontSize: 18,
    fontWeight: '700',
    fontFamily: 'DINPro-Bold'
  },
  row: {
    backgroundColor: 'white',
    flexDirection: 'row',
    flex: 1
  },
  overlay: {
    flex: 1,
    position: 'absolute',
    flexDirection: 'column',
    left: 0,
    top: 0,
    opacity: 0.7,
    backgroundColor: 'white'
  },
  activityIndicator: {
    flex:1,
    justifyContent: 'center',
    alignItems: 'center',
    height: 80
  }
});

export default styles;