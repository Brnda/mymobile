import {StyleSheet} from 'react-native';

const styles = StyleSheet.create({
  choiceBoxes: {
    flexDirection: 'row',
    justifyContent: 'center',
    position: 'absolute',
    bottom: 50,
    left: 0,
    right: 0
  },
  choiceBox: {
    borderColor: 'black',
    borderStyle: 'solid',
    borderWidth: 2,
    padding: 20,
    marginLeft: 5,
    marginRight: 5,
    borderRadius: 7
  },
  qrCode: {
    marginRight: 15
  },
  inviteCode: {
    marginLeft: 15
  },
  inviteText: {
    paddingTop: 10,
    color: 'white',
    fontSize: 12,
    alignItems: 'center'
  },
  inviteLabel: {
    justifyContent: 'center',
    alignItems: 'center',
    flexDirection: 'row',
    flex: 1
  }
});

export default styles;