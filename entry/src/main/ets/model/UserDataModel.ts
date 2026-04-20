
import { AppStorageV2 } from '@kit.ArkUI';

class UserDataModel {
  isLoggedIn: boolean = false;
  username: string = '';

  constructor() {
    console.log('UserDataModel created');
  }
}

export { UserDataModel };