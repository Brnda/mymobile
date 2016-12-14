import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  container: {
    flex: 1,
    //justifyContent: 'center',
    backgroundColor: '#fff',
    flexDirection: 'column',
    alignItems: 'center'
  },
  message: {
    color: '#272727',
    fontFamily: 'DINPro',
    fontSize: 21
  },
  divider: {
    backgroundColor: 'black',
    height: 1,
    marginTop: 6,
    marginBottom: 10,
    width: 350
  },
  title: {
    color: 'black',
    fontFamily: 'DINPro',
    fontSize: 21,
    marginTop: 10
  },
  profileImage: {
    height: 160,
    width: 160,
    marginTop: 0,
    marginBottom: 10
  },
  rowWithText: {
    flexDirection: 'row',
    marginBottom: 10
  },
  rowHeader: {
    fontFamily: 'DINPro',
    fontSize: 17,
    marginRight: 10,
    fontWeight: 'bold'
  },
  rowValue: {
    fontFamily: 'DINPro',
    fontSize: 17
  },
  rowWithSwitch: {
    flexDirection: 'row',
    marginLeft: 10,
  },
  switchQuestion: {
    fontFamily: 'DINPro',
    fontSize: 17,
    width: 280,
    marginRight: 10,
    marginBottom: 10
  },
  logout: {
    fontFamily: 'DINPro',
    fontSize: 17,
    color: 'red'
  },
  header: {
    backgroundColor: 'white',
    alignItems: 'center',
    marginTop: 10,
    // borderColor: 'black',
    // borderStyle: 'solid',
    // borderBottomWidth: 1,
    marginLeft: 5,
    marginRight: 5,
    paddingTop: 6,
    paddingBottom: 0
  },
  headerText: {
    fontSize: 18,
    fontWeight: '700',
    fontFamily: 'DINPro-Bold'
  },
});

export default styles;