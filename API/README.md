# **API** #

Classe base de API, com suporte a cache.
Automaticamente faz um multipart/form-data se algum dos parametros for Data ou um array de Data.
Zero dependencias externas.

Temos 3 arquivos:

* `API.swift`
  * Declaração do enum de método HTTP e opções de cache
  * Helper methods
  * Encoding de parametros
  * Builder de requests multipart/form-data
  * Classe de monitoramento de progresso de requests
  * Declaração do `RequestError`

  Você provavelmente não vai precisar se preocupar com nada por aqui
* `APICacheManager.swift`
  * Todo o gerenciamento de cache em disco e em memória. O tamanho máximo do cache em memória pode ser alterado. É 1MB por padrão e se encontra em `Constants.inMemoryCacheDefaultMaxSize`.
* `APIRequest.swift`
  * A classe principal com que voce vai trabalhar.
  * Define constants como `baseURL` e `apiPath`
  * Responsável por fazer o request em si
  * Declaração da extensão do `RequestError` com suporte para `localizedDescription`. Essa extensão (encontrada no fim do arquivo) deve ser modificada para suportar o formato de erro enviado pela API. 

O primeiro passo é adicionar o seguinte import no seu bridging header:

```objc
#import <CommonCrypto/CommonCrypto.h>
```

O cache manager usa métodos do `CommonCrypto` para gerar hashes.

O segundo passo é alterar as constants necessárias no `APIRequest.swift`

```swift
struct Constants {
    static let baseURL = URL(string: "https://api.spotify.com")!
    static let apiPath = "v1/"
    static let authenticationHeaders = ["access-token", "client", "uid"]
    static let authenticationHeadersDefaultsKey = "authenticationHeaders"
}
```

* A `baseURL` e `apiPath` você certamente vai precisar alterar.
* `authenticationHeaders` é um array com o nome dos headers de autenticação usados pela API, já por padrão preenchido com os headers usados por nossas APIs internas. Em toda response a classe verifica a existencia de algum desses headers e salva no `UserDefaults`, usando a chave definida em `authenticationHeadersDefaultsKey`, e em todo request esses headers são adicionados automaticamente.

Feito isso, vamos falar de **uso da `APIRequest` e organização**:

* Evite usar essa classe diretamente. Você deve criar subclasses dessa classe, agrupando requests. Por exemplo: você pode ter uma classe `AuthenticationAPI` com todos os requests de autenticação (login, cadastro, esqueci a senha, login com facebook, etc) e outra classe `UserAPI` com requests relacionados ao usuário (alterar usuario e outros que possam estar relacionados). 
* Essa subclasse deve ter métodos `static` que retornem uma instancia de tal subclasse, de preferencia marcados com `@discardableResult` pois nem sempre o objeto retornado por esse método será usado.

Exemplo:

```swift
class AuthenticationAPI: APIRequest {
    
    @discardableResult
    static func loginWith(username: String, password: String, callback: ResponseBlock<User>?) -> AuthenticationAPI {
        
        let request = AuthenticationAPI(method: .post, path: "login", parameters: ["username": username, "password": password], urlParameters: nil, cacheOption: .networkOnly) { (response, error, cache) in
            if let error = error {
                callback?(nil, error, cache)
            } else if let response = response as? [String: Any] {
                let user = User(dictionary: response)
                callback(user, nil, cache)
            }
        }
        request.shouldSaveInCache = false
        request.makeRequest()

        return request
    }
}
```

Vamos por partes:

* Na declaração do método vemos do uso do `ResponseBlock`, que recebe 3 parametros: um tipo `T`, definido na declaração (ali no caso é o `User`), um `RequestError` e um `Bool` indicando se o request veio do cache ou não. É importante declarar corretamente no `ResponseBlock` qual será o tipo da resposta. A `APIRequest` usa o `Any` por padrão.
* Já na implementação do método, declaramos um variável `request` e nela inicializamos uma instancia da nossa `AuthenticationAPI`. Vamos analisar os parametros:
  * `method`: um `HTTPMethod` (enum), o método HTTP que será usado no request
  * `path`: path relativo a baseURL + apiPath setados anteriormente
  * `parameters`: dicionário com os parametros a serem enviados no corpo da requisição (enviados como JSON)
  * `urlParameters`: dicionário com os parametros a serem incluídos na URL. Pode ser usado em conjunto com o `parameters`. Ou seja, você pode ter um POST também com `urlParameters`.
  * `cacheOption`: a opção de cache para esse request (mais detalhes abaixo)
  * `completion`: um `ResponseBlock<Any>`, chamado com a resposta do request

  Além desses parametros da inicialização, há outros que você pode configurar após a inicialização:
  * `baseURL`: por padrão é a baseURL + apiPath declaradas no `Constants` mas pode ser alterada
  * `extraHeaders`: dicionário com headers a serem enviados na request (além dos padrões)
  * `suppressErrorAlert`: por padrão, no caso de erro, a classe mostra um alerta com uma descrição do erro. Você pode setar essa propriedade para `true` para impedir que esse alerta seja mostrado.
  * `uploadBlock` e `downloadBlock`: um `ProgressBlock` que tem dois parametros: total de bytes enviados e total de bytes totais. Reportam o progresso do upload/download do request (útil para mostrar um progresso para o usuário no envio de arquivos grandes).
  * `shouldSaveInCache`: podemos ver esse parametro ser setado no exemplo acima. Por padrão `true`, define se um request deve ser guardado no cache. No caso de métodos de autenticação, é sempre ideal desativar.
  * `parameterEncoder`: o objeto usado para encoding dos parametros na request. Por padrão usa o `JSONParameterEncoder`, você pode alterar para o `URLParameterEncoder` ou, se necessário, criar seu próprio encoder que conforme ao protocol `ParameterEncoding`.
* Logo depois da declaração da variavel `request`, chamamos o método `makeRequest()` que cria e inicia a `URLSessionDataTask`, e a seta na propriedade `task` da instância. Ela pode ser usada para cancelar o request.
* Finalmente retornamos a instancia de `AuthenticationAPI` criada

## **Error handling** ##

A classe define um tipo de erro próprio: ```RequestError```

```swift
enum RequestError: Error {
    case error(responseObject: Any?, urlResponse: HTTPURLResponse?, originalError: Error?)
}
```

Apesar de ter apenas um erro definido, ele contém o `responseObject`, com o corpo da resposta da API (se disponível), a `HTTPURLResponse`, util para acessar dados como o statusCode, e finalmente o `Error` original reportado pelo sistema. Quando ocorre um erro, não é retornado um valor para o parametro `response` do `ResponseBlock`, apesar para o `error`, que contém todas as informações necessárias. 

Por padrão a classe mostra um ```UIAlertController``` com o ```localizedDescription``` do ```RequestError```. Você pode alterar o tratamento do `localizedDescription` na extensão encontrada no fim do `APIRequest.swift`. A implementação padrão verifica a existência de uma string na chave `error` do `responseObject` e mostra ela.

Exemplo de uso:

```swift
UserAPI.profile { (response, error, cache) in
    
    if let response = response {
        // request ok, "response" is a User
    } else if let error = error, case let API.RequestError.error(responseObject, urlResponse, originalError) = error {
        if let urlResponse = urlResponse, urlResponse.statusCode == 401 {
            // logout user
        } else if let responseObject = responseObject as? [String: Any], errorMessage = responseObject["error_message"] {
            // show "errorMessage"
        } else {
            // show originalError.localizedDescription
        }
    }
}
```

## **Cache** ##

São 3 opções de cache ao fazer o request:

* ```CacheOption.cacheOnly``` - se o request estiver em cache, retorna no block **apenas** a resposta do cache, não fazendo um request. Porem se o request não estiver em cache, o request é feito.
* ```CacheOption.networkOnly``` - ignora completamente o cache e faz o request, retornando apenas a resposta dele.
* ```CacheOption.both``` - se o request estiver em cache, retorna no block a resposta do cache e, posteriormente, a resposta do request. Se o request não estiver em cache, retorna apenas a resposta do request.

O funcionamento do cache é simples, ele cria um nome de arquivo baseado num hash das seguintes informações:
* Método HTTP
* Path
* Parametros e seus valores

Sempre com a extensão de arquivo ```.apicache``` e salva nesse arquivo os dados do ```responseObject```. 

Todo o cache é gerenciado pela classe ```APICacheManager```. Alem do cache em disco, também há um cache em memória. Por padrão tem um tamanho máximo de 1MB, mas esse tamanho pode ser configurado na propriedade ```inMemoryCacheMaxSize``` do ```APICacheManager```. Na inicialização dessa classe, todos os arquivos de cache sao carregados na memória ATÉ que o limite seja atingido. Caso o limite do cache seja atingido ao longo do uso do app, é feita uma otimização: são mantidos em memória os items mais acessados (essa contagem é feita internamente). 

Por padrão **todos** os requests são salvos no cache, mas em alguns casos é ideal desativar isso. Por exemplo, um request que você chama várias vezes com parametros diferentes sempre (pode acabar criando um alto volume de dados no aparelho do usuário), ou requests que incluam dados sensíveis. Então podemos desativar _por request_ o cache, como mostrado no exemplo anterior.

## **Mais opções** ##

Na sua subclasse do `APIRequest` você tem completo controle de todos os detalhes do request. Se voce precisar interagir com uma API diferente, que fique em outro endereço, você pode juntar todos esses requests em uma subclasse e alterar a propriedade `baseURL`:

```swift
class AuthenticationAPI: APIRequest {
    
    override init(method: API.HTTPMethod, path: String, parameters: [String : Any]?, urlParameters: [String : Any]?, cacheOption: API.CacheOption, completion: ResponseBlock<Any>?) {
        super.init(method: method, path: path, parameters: parameters, urlParameters: urlParameters, cacheOption: cacheOption, completion: completion)
        
        self.baseURL = URL(string: "https://mansaothugstronda.com/api/v1")!
    }
}
```

Assim todos os requests usarão essa `baseURL`, sem precisar modificar em cada request.

Agora vamos supor que em todo request dessa API voce precise mandar, por exemplo, o email do usuário, mas você não quer em todo request escrever isso manualmente. Nesse caso a gente implementa o didSet da propriedade `parameters`:

```swift
override var parameters: [String : Any]? {
    didSet {
        if parameters != nil {
            super.parameters?["email": userEmail]
        } else {
            super.parameters = ["email": userEmail]
        }
    }
}
```

Se o parameters não for nil, apenas setamos a nova key no dicionário. Se for, criamos um novo dicionário com a key. Note que nesse caso a gente deve setar usando o `super` e não o `self`.
