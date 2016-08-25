import { StyleSheet } from 'react-native';

const styles = StyleSheet.create({
  choiceBoxes: {
    flexDirection: 'row',
    justifyContent: 'center',
    position: 'absolute',
    bottom: 150,
    left: 0,
    right: 0,
  },
  choiceBox: {
    backgroundColor: 'white',
    borderColor: 'black',
    borderStyle: 'solid',
    borderWidth: 2,
    padding: 20,
    marginLeft: 5,
    marginRight: 5,
    borderRadius: 7
  }
});

export default styles;