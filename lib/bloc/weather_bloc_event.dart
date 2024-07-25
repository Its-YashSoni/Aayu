part of 'weather_bloc_bloc.dart';


// abstract class WeatherBlocEvent extends Equatable {
//   const WeatherBlocEvent();
//
//   @override
//   List<Object> get props => [];
// }
//
// class FetchWeather extends WeatherBlocEvent {
//   final String cityName;
//
//   const FetchWeather(this.cityName);
//
//   @override
//   List<Object> get props => [cityName];
// }


abstract class WeatherBlocEvent extends Equatable {
  const WeatherBlocEvent();

  @override
  List<Object> get props => [];
}

class FetchWeatherByCoordinates extends WeatherBlocEvent {
  final double latitude;
  final double longitude;

  const FetchWeatherByCoordinates(this.latitude, this.longitude);

  @override
  List<Object> get props => [latitude, longitude];
}



//
// sealed class WeatherBlocEvent extends Equatable {
//   const WeatherBlocEvent();
//
//   @override
//   List<Object> get props => [];
// }
//
// class FetchWeather extends WeatherBlocEvent {
// 	final Position position;
//
// 	const FetchWeather(this.position);
//
// 	@override
//   List<Object> get props => [position];
// }
