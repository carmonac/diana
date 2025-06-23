class ActionInvoker {
  static dynamic invoke<T extends Function>(T action, List<dynamic> args) {
    switch (args.length) {
      case 0:
        return action();
      case 1:
        return action(args[0]);
      case 2:
        return action(args[0], args[1]);
      case 3:
        return action(args[0], args[1], args[2]);
      case 4:
        return action(args[0], args[1], args[2], args[3]);
      case 5:
        return action(args[0], args[1], args[2], args[3], args[4]);
      default:
        return Function.apply(action, args);
    }
  }
}
