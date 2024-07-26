OPTSTRING="m:"

while getopts ${OPTSTRING} opt; do
  case ${opt} in
    m)
        echo "HELLO: ${OPTARG}"
        exit 2
    :)
      echo "Option -${OPTARG} requires an argument."
      exit 2
      ;;
    ?)
      echo "Invalid option: -${OPTARG}."
      exit 2
      ;;
  esac
done

