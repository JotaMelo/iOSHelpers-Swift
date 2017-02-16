# **Mappable** #

Fácil mapeamento de JSON com esse simples protocolo.

Suporta os seguintes tipos: 

* `String`
* `Float`
* `Double`
* `Int`
* `Double`
* `Bool` - alem do `Bool`, também converte corretamente as strings `"true"`, `"false"`, `"0"`, `"1"`.
* `Date` - se for uma string converte usando o date format configurado, se for um `Int`/`Float` assume ser uma timestamp em segundos
* `URL` (a partir de uma string)
* `RawRepresentable` (enums)
* `Array`
* `Array` de `Mappable`s
* `Mappable`
* Optionals de todos acima

O primeiro passo é alterar no arquivo `Mappable.swift` o formato de data padrão usado pela API. Essa variável se encontra na classe `Mapper`.

Agora vamos ao exemplo. Supondo que temos o seguinte JSON:
```json
{
    "id": "123",
    "user_name": "fulana22k",
    "email": "fulana22k@hotmail.com",
    "is_first_login": true,
    "register_date": "2015/08/21 15:45:45",
    "favorite_pizza": {
        "pizza_id": 5,
        "name": "Catuperoni",
        "size": 1,
        "number_of_ingredients": null
    },
    "ordered_pizzas": [{
        "pizza_id": 5,
        "name": "Catuperoni",
        "size": 1,
        "number_of_ingredients": null
    }, {
        "pizza_id": 10,
        "name": "Calabresa",
        "size": 2,
        "number_of_ingredients": 2
    }]
}
```

Criamos o seguinte:
```swift
enum PizzaSize: Int {
    case small
    case medium
    case large
}

struct Pizza: Mappable {
    
    let pizzaID: Int
    let name: String
    var size: PizzaSize
    var numberOfIngredients: Int?
    
    init(mapper: Mapper) {
        
        self.pizzaID = mapper.keyPath("pizza_id")
        self.name = mapper.keyPath("name")
        self.size = mapper.keyPath("size")
        self.numberOfIngredients = mapper.keyPath("number_of_ingredients")
    }
}
```

```objc
struct User: Mappable {
    
    var id: Int
    var userName: String
    var email: String
    var isFirstLogin: Bool
    var registerDate: Date
    var favoritePizza: Pizza
    var orderedPizzas: [Pizza]
    var favoritePizzaName: String
    var lastOrderedPizzaName: String
    
    init(mapper: Mapper) {
        
        mapper.dateFormat = "yyyy/MM/dd HH:mm:ss"
        
        self.id = mapper.keyPath("id")
        self.userName = mapper.keyPath("user_name")
        self.email = mapper.keyPath("email")
        self.isFirstLogin = mapper.keyPath("is_first_login")
        self.registerDate = mapper.keyPath("register_date")
        self.favoritePizza = mapper.keyPath("favorite_pizza")
        self.orderedPizzas = mapper.keyPath("ordered_pizzas")
        self.favoritePizzaName = mapper.keyPath("favorite_pizza.name")
        self.lastOrderedPizzaName = mapper.keyPath("ordered_pizzas.0.name")
    }
}
```

O que devemos notar:

* Todo objeto que conforma ao `Mappable` precisa implementar o `init(mapper:)`
* `Mapper` é uma classe usada apenas nesse init. Nela pode ser configurado o dateFormat a ser usado para esse model, caso ele seja diferente do padrão configurado no `Mappable.swift`.
* Sua principal interação com a `Mapper` é pelo método `keyPath(_:)`. A string que você passa nesse método é uma key path, que representa um valor no dicionário com que foi inicializado o objeto. Por exemplo, para acessar a propriedade `name` dentro do dicionário `favorite_pizza`, foi passada a key path `favorite_pizza.name`. E para acessar o nome do primeiro item do array `ordered_pizzas`, a key path usada foi `ordered_pizzas.0.name`.
* Lembre de declarar como `Optional` os parametros que podem ser `nil`, como o `numberOfIngredients` da `Pizza`.

Considere que temos aquele JSON acima em uma variável chamada `response`:

```swift
let user = User(dictionary: response)
```

E está inicializado o `User`! O `init(dictionary:)` está definido em uma protocol extension do `Mappable`. ele cria uma instancia do `Mapper` com tal dicionário e chama o `init(mapper:)` para finalizar a inicialização.
